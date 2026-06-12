import Foundation

// neden: sonuç ekranında doğru/yanlış ayrımıyla cümle ve kullanıcı cevabı gösterilir
struct SentenceResult: Hashable {
    let sentence: Sentence
    // kullanıcının yerleştirdiği kelimeler (boşluk ile birleşik)
    let userAnswer: String
    let isCorrect: Bool
}

/// Aktif cümle sorusunun ekrana yansıyan durumu — swipe-geçmiş için snapshot
struct SentenceQuestionState: Hashable {
    let chapterId: String
    let sentence: Sentence
    var availableWords: [String] // Henüz kullanılmayan kelimeler
    var placedWords: [String]    // Kullanıcının sıraladığı kelimeler
    let questionIndex: Int
    let totalQuestions: Int
    var correctCount: Int
    var wrongCount: Int
    var direction: QuizDirection = .trToEn
    var isChecked: Bool = false
    var isCorrect: Bool? = nil
    // neden: DB yazma başarısız olursa kullanıcıya uyarı gösterilir
    var warningMessage: String? = nil

    var remainingQuestions: Int { totalQuestions - questionIndex - 1 }

    // neden: yöne göre hangi metin gösterilip hangisi cevaplanacak belirtir
    var promptText: String {
        direction == .trToEn ? sentence.turkish : sentence.english
    }

    var answerText: String {
        direction == .trToEn ? sentence.english : sentence.turkish
    }
}
