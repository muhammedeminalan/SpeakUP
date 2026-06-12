import Foundation

// neden ayrı struct: yanlış cevap detayı state ile birlikte taşınıyor,
// sonuç ekranında "seçilen vs doğru" karşılaştırması için kullanılıyor
struct WrongAnswerDetail: Hashable {
    let word: Word
    let selectedAnswer: String
    var direction: QuizDirection = .trToEn

    // neden: yön farklıysa doğru cevap Türkçe olur
    var correctAnswer: String {
        direction == .trToEn ? word.english : word.turkish
    }
}

/// Aktif sorunun ekrana yansıyan tüm durumu — Flutter'daki WordQuizQuestion state'i.
/// neden struct snapshot: swipe-geçmiş özelliği eski soruları aynen gösterebilsin
struct WordQuizQuestionState: Hashable {
    let chapterId: String
    let currentWord: Word
    let options: [String]
    let questionIndex: Int
    let totalQuestions: Int
    let correctCount: Int
    let wrongCount: Int
    var selectedAnswer: String? = nil
    var isAnswered: Bool = false
    var warningMessage: String? = nil
    var direction: QuizDirection = .trToEn

    // neden: yöne göre doğru cevap İngilizce veya Türkçe olabilir
    var correctAnswer: String {
        direction == .trToEn ? currentWord.english : currentWord.turkish
    }

    // neden: yöne göre soru metni İngilizce veya Türkçe olabilir
    var questionText: String {
        direction == .trToEn ? currentWord.turkish : currentWord.english
    }

    var isCorrect: Bool { selectedAnswer == correctAnswer }
    var remainingQuestions: Int { totalQuestions - questionIndex - 1 }
}
