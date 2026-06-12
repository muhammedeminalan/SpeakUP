import AVFoundation

/// AVSpeechSynthesizer'ı saran servis — dil, hız ve durum yönetimi tek yerden.
/// Flutter'daki flutter_tts tabanlı TtsService'in birebir karşılığı.
@Observable
final class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    private(set) var isPlaying = false

    // neden track: speak(withLocale:) bitince orijinal dile geri dönmek için
    private var currentLocale = "en-GB"
    private var restoreLocale: String?

    /// Kullanıcının ayarladığı baz hız — AppSettings tarafından güncellenir.
    /// neden 0.45: varsayılan 0.5 öğrenciler için hızlı, 0.45 netlik sağlar
    var baseRate: Double = 0.45

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    private func configureAudioSession() {
        // neden playback + defaultToSpeaker benzeri ayar: sessiz anahtar açıkken
        // de ses çıksın, Bluetooth kulaklık destekli olsun
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth]
            )
        } catch {
            // Ses oturumu kurulamazsa TTS yine varsayılan oturumla çalışır — kritik değil
        }
    }

    /// Dili değiştir — sonraki tüm okumalar bu locale ile yapılır
    func setLocale(_ locale: String) {
        currentLocale = locale
    }

    /// Geçici locale ile okuma: bitince orijinal locale'e döner
    /// neden: Türkçe metin EN→TR yönünde Türkçe aksanla okunmalı
    func speak(_ text: String, withLocale locale: String) {
        stopIfPlaying()
        restoreLocale = currentLocale
        currentLocale = locale
        isPlaying = true
        synthesizer.speak(makeUtterance(text, rate: baseRate))
    }

    /// Cümle veya uzun metin okuma — normal hız
    func speak(_ text: String) {
        stopIfPlaying()
        isPlaying = true
        synthesizer.speak(makeUtterance(text, rate: baseRate))
    }

    /// Tek kelime okuma — daha yavaş hız, daha net telaffuz
    /// neden ayrı metot: tek kelimeler cümle bağlamı olmadan okunduğu için
    /// biraz yavaşlatmak anlaşılırlığı artırır
    func speakWord(_ word: String) {
        stopIfPlaying()
        isPlaying = true
        // neden baseRate - 0.07: tek kelime bağlamsız okunuyor, biraz yavaş daha net
        let wordRate = min(max(baseRate - 0.07, 0.1), 1.0)
        synthesizer.speak(makeUtterance(normalizeWord(word), rate: wordRate))
    }

    func stop() {
        isPlaying = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    // ── Yardımcılar ────────────────────────────────────────────────────────

    private func stopIfPlaying() {
        if isPlaying { stop() }
    }

    private func makeUtterance(_ text: String, rate: Double) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceForLocale(currentLocale)
        // AVSpeech hız ölçeği 0–1, flutter_tts ile aynı aralık — doğrudan eşleme
        utterance.rate = Float(rate)
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        return utterance
    }

    /// Cihazdaki sesler arasından verilen locale'e uyan birini seç
    /// Önce tam eşleşme, sonra dil kodu eşleşmesi
    private func voiceForLocale(_ locale: String) -> AVSpeechSynthesisVoice? {
        if let exact = AVSpeechSynthesisVoice(language: locale) { return exact }
        let langCode = locale.split(separator: "-").first.map(String.init)?.lowercased() ?? locale
        return AVSpeechSynthesisVoice.speechVoices()
            .first { $0.language.lowercased().hasPrefix(langCode) }
    }

    /// TTS'in yanlış okuyabileceği kelimeleri normalize eder.
    /// neden map: motor bağımsız çalışır, cihazdan cihaza fark gözetmez
    private func normalizeWord(_ word: String) -> String {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // Bilinen sorunlu kelimeler → TTS'in doğru okuduğu alternatif
        // UYARI: buraya eklenecek her değer gerçek bir İngilizce kelime
        // olmamalı; "I'll"→"ill" gibi eşlemeler yanlış anlam yaratır
        let pronunciationMap: [String: String] = [
            // ── Tek harf / çok kısa ──────────────────────────────────────
            "i": "I.",  // Roman rakamı I ile karışıyor
            "a": "a.",  // harf adı "ay" yerine artikel olarak okusun
            // ── Güvenli kısaltmalar (gerçek kelimeyle çakışmıyor) ────────
            "mr": "mister",
            "mrs": "missus",
            "dr": "doctor",
            "etc": "et cetera",
        ]

        // Map'te varsa onu kullan, yoksa sonuna nokta ekle —
        // nokta "bu tam bir kelime" sinyali verir ve doğru telaffuzu tetikler
        return pronunciationMap[lower] ?? "\(trimmed)."
    }

    private func finishPlayback() {
        isPlaying = false
        // neden restore: speak(withLocale:) sonrasında orijinal dile dönülür
        if let restore = restoreLocale {
            restoreLocale = nil
            currentLocale = restore
        }
    }

    // ── AVSpeechSynthesizerDelegate ────────────────────────────────────────
    // Her durumda isPlaying sıfırlanır — buton takılıp kalmaz

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finishPlayback()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finishPlayback()
    }
}
