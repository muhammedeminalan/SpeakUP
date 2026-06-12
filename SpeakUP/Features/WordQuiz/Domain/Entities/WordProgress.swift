import Foundation

/// Bir kelimenin öğrenme durumu — domain entity (storage'dan bağımsız)
struct WordProgress {
    let chapterId: String
    let wordId: Int
    var isLearned: Bool
    var correctCount: Int = 0
    var wrongCount: Int = 0
}
