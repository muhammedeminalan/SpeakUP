import SwiftUI

/// Semantik tema renkleri — Flutter'daki ColorScheme'in karşılığı.
/// neden dinamik (light/dark) renkler: tema değişince her görünüm otomatik uyum
/// sağlar, görünüm başına if-else gerekmez — tema dengesizliği kökten önlenir.
enum AppTheme {
    // ── Sabit semantik renkler — her iki temada aynı ───────────────────────
    static let correct = AppColors.green       // Doğru cevap
    static let wrong = AppColors.red           // Yanlış cevap
    static let xpGold = AppColors.amber        // XP rozeti
    static let primaryBlue = AppColors.accent  // AppBar, chip, CTA
    static let primaryBlueDark = AppColors.accent2 // Gradient bitiş

    // ── Temaya duyarlı yüzeyler ────────────────────────────────────────────
    // Material 3 colorScheme eşlemesi: (light, dark)
    static let surface = Color(light: 0xF5F6FA, dark: 0x0A0F1A)            // scaffold zemin
    static let onSurface = Color(light: 0x1A1E2E, dark: 0xE8ECF5)          // ana metin
    static let surfaceContainer = Color(light: 0xFFFFFF, dark: 0x141D30)   // kart, input
    static let surfaceContainerHigh = Color(light: 0xEBEDF5, dark: 0x1B2742) // hover, vurgu
    static let onSurfaceVariant = Color(light: 0x5B6688, dark: 0x9AA6C2)   // ikincil metin
    static let outline = Color(light: 0xDDE0ED, dark: 0x243154)            // standart border
    static let outlineVariant = Color(light: 0xEEF0F8, dark: 0x0F1626)     // hafif border

    static let primary = AppColors.accent
    static let onPrimary = Color(light: 0xFFFFFF, dark: 0x0A0F1A)
    static let primaryContainer = AppColors.accent.opacity(0.12)
    static let onPrimaryContainer = Color(light: 0x5B6DFF, dark: 0x7C8CFF)
    static let secondaryContainer = Color(light: 0xEBEDF5, dark: 0x1B2742)
    static let onSecondaryContainer = Color(light: 0x1A1E2E, dark: 0xE8ECF5)
    static let error = AppColors.red
}
