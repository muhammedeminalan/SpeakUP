import SwiftUI

// ── Route payload'ları — Flutter'daki route_payloads.dart karşılığı ──────────

struct WordQuizPayload: Hashable {
    let chapterId: String
    let words: [Word]
    let settings: QuizSettings
    // neden ayrı: retry'da words = sadece yanlışlar, optionPool = tüm bölüm
    // kelimeleri; böylece sorular az ama şıklar hep 4 seçenekli olur
    var optionPool: [Word]? = nil
    // neden flag: oturum nesnesi yerine bayrak — oturum QuizSessionStore'da yaşar
    var resume: Bool = false
}

struct WordQuizResultPayload: Hashable {
    let chapterId: String
    let chapterWords: [Word]
    let wrongWordIds: [Int]
    let attemptedWordIds: [Int]
    let defaultQuestionCount: Int
    let correct: Int
    let total: Int
    let xpEarned: Int
    let wrongAnswerDetails: [WrongAnswerDetail]
    let correctWords: [Word]
    var direction: QuizDirection = .trToEn
}

struct SentenceBuilderPayload: Hashable {
    let chapterId: String
    let sentences: [Sentence]
    let questionCount: Int
    var direction: QuizDirection = .trToEn
    var resume: Bool = false
}

struct SentenceResultPayload: Hashable {
    let chapterId: String
    let allSentences: [Sentence]
    let wrongSentenceIds: [Int]
    let attemptedSentenceIds: [Int]
    let defaultQuestionCount: Int
    let correct: Int
    let total: Int
    let xpEarned: Int
    let sentenceResults: [SentenceResult]
}

struct ProgressPayload: Hashable {
    let chapterId: String
    let words: [Word]
    let sentences: [Sentence]
}

// ── Router — merkezi navigasyon yönetimi ─────────────────────────────────────
// neden: View'lar arası geçişleri tek noktadan kontrol etmek, test edilebilirlik

@Observable
final class Router {
    var path = NavigationPath()

    enum Destination: Hashable {
        case chapterDashboard(Chapter)
        case wordQuiz(WordQuizPayload)
        case wordQuizResult(WordQuizResultPayload)
        case sentenceBuilder(SentenceBuilderPayload)
        case sentenceResult(SentenceResultPayload)
        case progress(ProgressPayload)
        case settings
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    // Flutter'daki pushReplacement karşılığı — quiz biter, yerine sonuç gelir
    func replace(with destination: Destination) {
        if !path.isEmpty { path.removeLast() }
        path.append(destination)
    }
}
