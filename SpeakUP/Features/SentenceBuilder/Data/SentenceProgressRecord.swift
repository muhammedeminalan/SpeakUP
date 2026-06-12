import Foundation
import SwiftData

/// Cümle progress için SwiftData kaydı — kelime kayıtlarından ayrı model
@Model
final class SentenceProgressRecord {
    @Attribute(.unique) var key: String
    var chapterId: String
    var sentenceId: Int
    var isLearned: Bool
    var correctCount: Int
    var wrongCount: Int

    init(chapterId: String, sentenceId: Int, isLearned: Bool, correctCount: Int, wrongCount: Int) {
        self.key = Self.makeKey(chapterId: chapterId, sentenceId: sentenceId)
        self.chapterId = chapterId
        self.sentenceId = sentenceId
        self.isLearned = isLearned
        self.correctCount = correctCount
        self.wrongCount = wrongCount
    }

    static func makeKey(chapterId: String, sentenceId: Int) -> String {
        "\(chapterId)#\(sentenceId)"
    }

    var asEntity: SentenceProgress {
        SentenceProgress(
            chapterId: chapterId,
            sentenceId: sentenceId,
            isLearned: isLearned,
            correctCount: correctCount,
            wrongCount: wrongCount
        )
    }
}
