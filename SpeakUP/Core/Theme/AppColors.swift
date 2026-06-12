import SwiftUI

/// Kelime & Cümle uygulaması renk paleti — Indigo accent
/// neden statik sabitler: renk değişince tek yerden yönetilsin
enum AppColors {
    // ─────────────────────────────────────────
    // Accent (Indigo)
    // ─────────────────────────────────────────
    static let accent = Color(hex: 0x7C8CFF)   // Birincil aksan
    static let accent2 = Color(hex: 0x5B6DFF)  // Gradient bitiş, hover

    // ─────────────────────────────────────────
    // Semantic
    // ─────────────────────────────────────────
    static let green = Color(hex: 0x34D399)    // Doğru
    static let red = Color(hex: 0xF87171)      // Yanlış
    static let amber = Color(hex: 0xFBBF24)    // Orta skor / XP

    // ─────────────────────────────────────────
    // Gradients
    // ─────────────────────────────────────────

    /// Ana sayfa / dashboard hero kartı
    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x6D7BFF), Color(hex: 0x4555E8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// AppBar gradyeni — Dodger Blue → koyu mavi yerine indigo paleti
    static let appBarGradient = LinearGradient(
        colors: [accent, accent2],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Soru kartı gradyeni
    static let questionCardGradient = LinearGradient(
        colors: [accent, accent2],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sayfa arka planı — açık/koyu temaya göre dikey gradyen
    /// neden tek fonksiyon: tüm sayfalar aynı zemini kullanır, kayma olmaz
    static func pageBackground(isDark: Bool) -> LinearGradient {
        let colors: [Color] = isDark
            ? [Color(hex: 0x070F20), Color(hex: 0x091834), Color(hex: 0x070F20)]
            : [Color(hex: 0xF8FAFF), Color(hex: 0xEEF3FF), Color(hex: 0xF8FAFF)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    /// Bölüm listesi kart gradyenleri — index'e göre döngüsel seçilir
    static let chapterGradients: [[Color]] = [
        [Color(hex: 0x1CB0F6), Color(hex: 0x0077CC)],
        [Color(hex: 0x58CC02), Color(hex: 0x2E8B00)],
        [Color(hex: 0xA560E8), Color(hex: 0x7B2FBE)],
        [Color(hex: 0xFFCB02), Color(hex: 0xFF8C00)],
        [Color(hex: 0x14D4F4), Color(hex: 0x0099BB)],
        [Color(hex: 0xFF6B9D), Color(hex: 0xCC3370)],
    ]

    /// Öğrenme modu kart gradyenleri
    static let modeQuizGradient = [Color(hex: 0x1CB0F6), Color(hex: 0x0077CC)]
    static let modeSentenceGradient = [Color(hex: 0x58CC02), Color(hex: 0x2E8B00)]
    static let modeProgressGradient = [Color(hex: 0xFFCB02), Color(hex: 0xFF8C00)]
}
