import SwiftUI

/// Kullanıcı font tercihini uygulayan modifier — Flutter'daki textScaler karşılığı.
/// neden .rounded: Nunito'nun yumuşak/dostane görünümüne en yakın sistem fontu;
/// font dosyası bundle'a eklemeden aynı hissi verir.
private struct ScaledFontModifier: ViewModifier {
    @Environment(AppSettings.self) private var settings

    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.system(size: size * settings.fontScale, weight: weight, design: .rounded))
    }
}

/// Ölçeklenmeyen sabit font — ayar ekranındaki örnek metin gibi yerler için
private struct FixedFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: .rounded))
    }
}

extension View {
    /// Kullanıcının metin boyutu tercihine göre ölçeklenen font
    func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight))
    }

    /// neden ayrı: global ölçekten etkilenmemesi gereken metinler için
    func fixedAppFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(FixedFontModifier(size: size, weight: weight))
    }
}
