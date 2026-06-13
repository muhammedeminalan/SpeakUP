import Foundation

/// WordProgress'in cümle karşılığı — aynı desen, farklı entity
struct SentenceProgress {
    let chapterId: String
    let sentenceId: Int
    var isLearned: Bool
    var correctCount: Int = 0
    var wrongCount: Int = 0
}
