import Foundation

extension Double {
    /// neden extension: hız etiketi mantığını tek yere toplar, UI'da tekrar etmez
    var speechRateLabel: String {
        if self <= 0.25 { return "Çok Yavaş" }
        if self <= 0.35 { return "Yavaş" }
        if self <= 0.50 { return "Normal" }
        if self <= 0.60 { return "Hızlı" }
        return "Çok Hızlı"
    }
}
