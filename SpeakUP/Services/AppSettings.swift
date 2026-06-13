import SwiftUI

// Kullanıcının seçebileceği 3 tema modu
enum AppThemeMode: String, CaseIterable {
    case system, light, dark

    // SwiftUI preferredColorScheme eşlemesi — nil sistem temasını takip eder
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum TTSAccent: String, CaseIterable {
    case british   // en-GB — varsayılan
    case american  // en-US
    case turkish   // tr-TR

    /// AVSpeechSynthesisVoice'a gönderilecek locale kodu
    var locale: String {
        switch self {
        case .british: return "en-GB"
        case .american: return "en-US"
        case .turkish: return "tr-TR"
        }
    }

    var label: String {
        switch self {
        case .british: return "İngiliz"
        case .american: return "Amerikan"
        case .turkish: return "Türkçe"
        }
    }

    var flag: String {
        switch self {
        case .british: return "🇬🇧"
        case .american: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }

    var detail: String {
        switch self {
        case .british: return "İngiltere İngilizcesi (en-GB)"
        case .american: return "Amerika İngilizcesi (en-US)"
        case .turkish: return "Türkiye Türkçesi (tr-TR)"
        }
    }

    // neden: Türkçe aksanı global TTS locale'ini değiştirmemeli —
    // İngilizce içerik her zaman İngilizce okunur, Türkçe ayrı handle edilir
    var isEnglish: Bool { self != .turkish }
}

/// Tüm kullanıcı tercihlerini tek yerden yöneten gözlemlenebilir depo.
/// Flutter'daki 6 ayrı Cubit'in karşılığı — neden tek sınıf: hepsi aynı
/// UserDefaults kaynağını kullanıyor, ayrı sınıflar gereksiz tekrar olurdu.
@Observable
final class AppSettings {
    // ── UserDefaults anahtarları — Flutter ile aynı isimler ────────────────
    private enum Keys {
        static let themeMode = "app_theme_mode"
        static let fontSize = "app_font_size_v2"
        static let autoAdvance = "auto_advance"
        static let muted = "tts_muted"
        static let speechRate = "speech_rate"
        static let accent = "tts_accent"
        static let lastEnglishAccent = "tts_last_english_accent"
    }

    // ── Font boyutu sınırları ──────────────────────────────────────────────
    static let minFontSize = 14
    static let maxFontSize = 32
    static let defaultFontSize = 16
    static let fontStep = 2

    // ── Okuma hızı sınırları ───────────────────────────────────────────────
    static let minRate = 0.2
    static let maxRate = 0.7
    static let defaultRate = 0.45

    private let defaults: UserDefaults
    private let tts: TTSService

    init(defaults: UserDefaults = .standard, tts: TTSService) {
        self.defaults = defaults
        self.tts = tts

        themeMode = AppThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "") ?? .system
        let savedFont = defaults.integer(forKey: Keys.fontSize)
        fontSize = (Self.minFontSize...Self.maxFontSize).contains(savedFont) ? savedFont : Self.defaultFontSize
        // neden default true: otomatik geçiş daha akıcı hissettiriyor — isteyen kapatır
        autoAdvance = defaults.object(forKey: Keys.autoAdvance) as? Bool ?? true
        isMuted = defaults.bool(forKey: Keys.muted)
        let savedRate = defaults.object(forKey: Keys.speechRate) as? Double ?? Self.defaultRate
        speechRate = min(max(savedRate, Self.minRate), Self.maxRate)
        accent = TTSAccent(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .british

        // Kaydedilmiş tercihleri TTS servisine uygula
        tts.baseRate = speechRate
        tts.setLocale(accent.isEnglish ? accent.locale : TTSAccent.british.locale)
    }

    // ── Tema ───────────────────────────────────────────────────────────────
    var themeMode: AppThemeMode {
        didSet { defaults.set(themeMode.rawValue, forKey: Keys.themeMode) }
    }

    // ── Font boyutu (14–32, 2'şer adım) ────────────────────────────────────
    var fontSize: Int {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }

    // Flutter'daki textScaler karşılığı — tüm metinler bu çarpanla ölçeklenir
    var fontScale: CGFloat { CGFloat(fontSize) / CGFloat(Self.defaultFontSize) }

    func increaseFontSize() {
        if fontSize < Self.maxFontSize { fontSize += Self.fontStep }
    }

    func decreaseFontSize() {
        if fontSize > Self.minFontSize { fontSize -= Self.fontStep }
    }

    // ── Otomatik soru geçişi ───────────────────────────────────────────────
    var autoAdvance: Bool {
        didSet { defaults.set(autoAdvance, forKey: Keys.autoAdvance) }
    }

    // ── Ses (mute) ─────────────────────────────────────────────────────────
    var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Keys.muted) }
    }

    // ── Okuma hızı ─────────────────────────────────────────────────────────
    var speechRate: Double {
        didSet {
            let clamped = min(max(speechRate, Self.minRate), Self.maxRate)
            if clamped != speechRate { speechRate = clamped; return }
            defaults.set(speechRate, forKey: Keys.speechRate)
            // neden: speakWord için de baz hız güncellenmeli
            tts.baseRate = speechRate
        }
    }

    // ── TTS aksanı ─────────────────────────────────────────────────────────
    var accent: TTSAccent {
        didSet {
            defaults.set(accent.rawValue, forKey: Keys.accent)
            // neden: Türkçe seçilince İngilizce TTS locale bozulmamalı —
            // Türkçe metin zaten speak(withLocale: "tr-TR") ile okunur
            if accent.isEnglish {
                // son İngilizce aksanı kaydet — yön değişince geri dönebilsin
                defaults.set(accent.rawValue, forKey: Keys.lastEnglishAccent)
                tts.setLocale(accent.locale)
            }
        }
    }

    private var lastEnglishAccent: TTSAccent {
        let saved = TTSAccent(rawValue: defaults.string(forKey: Keys.lastEnglishAccent) ?? "")
        guard let saved, saved.isEnglish else { return .british }
        return saved
    }

    /// Quiz başlarken çağrılır: cevap dili İngilizce ise İngilizce aksana,
    /// cevap dili Türkçe ise Türkçe aksana geç.
    /// neden promptIsTurkish=true → İngilizce aksan: TR→EN'de cevaplar İngilizce
    func autoSelectAccent(promptIsTurkish: Bool) {
        if promptIsTurkish {
            if !accent.isEnglish { accent = lastEnglishAccent }
        } else {
            if accent != .turkish { accent = .turkish }
        }
    }
}
