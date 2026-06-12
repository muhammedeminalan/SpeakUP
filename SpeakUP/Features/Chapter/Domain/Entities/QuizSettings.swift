import Foundation

// neden tek enum: hem kelime hem cümle quizinde aynı yön kavramı kullanılır
enum QuizDirection: Hashable {
    case trToEn // Türkçe soru → İngilizce cevap (varsayılan)
    case enToTr // İngilizce soru → Türkçe cevap
}

// Kelime quiz ayarları — ayar sheet'inden oluşturulur
struct QuizSettings: Hashable {
    let questionCount: Int // -1 = tüm kelimeler
    var direction: QuizDirection = .trToEn

    // Gerçek soru sayısını hesapla — mevcut kelime sayısını aşamaz
    func resolveCount(available: Int) -> Int {
        questionCount == -1 ? available : min(max(questionCount, 1), available)
    }
}

// Cümle kur ayarları
struct SentenceSettings: Hashable {
    let questionCount: Int // -1 = tüm cümleler
    var direction: QuizDirection = .trToEn

    func resolveCount(available: Int) -> Int {
        questionCount == -1 ? available : min(max(questionCount, 1), available)
    }
}
