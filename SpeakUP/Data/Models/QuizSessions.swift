import Foundation

/// Yarıda bırakılan kelime quizinin anlık görüntüsü — "Devam Et" için
struct WordQuizSession {
    let chapterId: String
    let chapterWords: [Word]
    let settings: QuizSettings
    let questions: [Word]
    let currentIndex: Int
    let correctCount: Int
    let wrongCount: Int
    let isAnswered: Bool
    let selectedAnswer: String?
    let currentOptions: [String]
    let wrongWordIds: [Int]
}

/// Yarıda bırakılan cümle kurma oturumunun anlık görüntüsü
struct SentenceBuilderSession {
    let chapterId: String
    let allSentences: [Sentence]
    let questionCount: Int
    let questions: [Sentence]
    let currentIndex: Int
    let correctCount: Int
    let wrongCount: Int
    let placedWords: [String]
    let availableWords: [String]
    let isChecked: Bool
    let isCorrect: Bool?
    let wrongSentenceIds: [Int]
}
