import SwiftUI
import UIKit

extension Color {
    // Hex'ten renk üretimi — Flutter'daki Color(0xFF...) karşılığı
    // neden: tasarım paleti hex olarak tanımlı, tek satırda taşınabilsin
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    // Açık/koyu temaya göre otomatik değişen renk
    // neden: tema dengesizliği olmasın — her semantik renk tek tanımdan,
    // sistem teması değişince UIKit dinamik renk mekanizması devreye girer
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}
