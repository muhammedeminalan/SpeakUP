import SwiftUI

/// Reusable TTS butonu — text'i okur, çalarken stop ikonu gösterir.
/// AppSettings.isMuted dinler: mute ise volume_off ikonu gösterir ve ses çıkarmaz.
struct SpeakButton: View {
    let text: String
    var size: CGFloat = 22
    var color: Color? = nil
    // neden nullable: nil ise mevcut TTS locale kullanılır,
    // değilse geçici olarak o locale ile okur (örn. Türkçe cevaplar)
    var locale: String? = nil

    @Environment(AppSettings.self) private var settings
    @Environment(TTSService.self) private var tts

    var body: some View {
        let isMuted = settings.isMuted
        let iconColor = color ?? AppTheme.primaryBlue

        Button(action: toggle) {
            Image(systemName: iconName(isMuted: isMuted))
                .font(.system(size: size))
                .foregroundStyle(isMuted ? iconColor.opacity(0.35) : iconColor)
                .frame(minWidth: 36, minHeight: 36)
        }
        // neden disabled: mute ise butona basılınca hiçbir şey olmasın
        .disabled(isMuted)
    }

    private func iconName(isMuted: Bool) -> String {
        if isMuted { return "speaker.slash.fill" }
        return tts.isPlaying ? "stop.fill" : "speaker.wave.2.fill"
    }

    private func toggle() {
        if tts.isPlaying {
            tts.stop()
        } else if let locale {
            tts.speak(text, withLocale: locale)
        } else {
            tts.speak(text)
        }
    }
}
