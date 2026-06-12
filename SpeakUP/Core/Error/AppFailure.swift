import Foundation

// Domain katmanı hata tipleri — kullanıcıya gösterilebilir mesaj taşır
// neden LocalizedError: SwiftUI alert/hata görünümlerinde doğrudan kullanılabilsin
enum AppFailure: LocalizedError {
    case data(String)
    case storage(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case let .data(message), let .storage(message), let .unknown(message):
            return message
        }
    }
}
