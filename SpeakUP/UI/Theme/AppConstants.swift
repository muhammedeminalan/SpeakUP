import Foundation

// Uygulama genelinde sabit değerler — magic number kullanımını önlemek için
// neden: aynı değeri birden fazla yerde yazmak yerine tek kaynaktan okuyoruz
enum AppConstants {
    // ── App Identity ───────────────────────────────────────────────────────
    static let appDisplayName = "SpeakUP"

    // ── Padding / Spacing ──────────────────────────────────────────────────
    static let paddingXS: CGFloat = 4
    static let paddingS: CGFloat = 8
    static let paddingM: CGFloat = 12
    static let paddingL: CGFloat = 16
    static let paddingXL: CGFloat = 20
    static let paddingXXL: CGFloat = 24

    // ── Border Radius ──────────────────────────────────────────────────────
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusChip: CGFloat = 24

    // ── Font Sizes ─────────────────────────────────────────────────────────
    static let fontXS: CGFloat = 11
    static let fontS: CGFloat = 12
    static let fontM: CGFloat = 14
    static let fontL: CGFloat = 15
    static let fontXL: CGFloat = 16
    static let fontXXL: CGFloat = 18
    static let fontTitle: CGFloat = 22

    // ── Min Heights ────────────────────────────────────────────────────────
    static let buttonHeight: CGFloat = 52
    static let dropZoneMinHeight: CGFloat = 80
    static let progressBarHeight: CGFloat = 8

    // ── Local Storage Keys ─────────────────────────────────────────────────
    // neden: onboarding sadece ilk açılışta gösterilsin
    static let onboardingSeenKey = "onboarding_seen_v1"
}
