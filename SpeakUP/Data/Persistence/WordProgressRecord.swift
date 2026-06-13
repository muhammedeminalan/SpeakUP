import Foundation
import SwiftData

/// SwiftData kalıcı kaydı — Flutter'daki sqflite word_progress tablosunun karşılığı.
/// neden SwiftData: iOS 17+ hedefte Apple'ın güncel kalıcılık çözümü;
/// @Observable ekosistemiyle doğal uyum, elle SQL/migration gerekmez.
@Model
final class WordProgressRecord {
    // chapterId + wordId birlikte benzersiz — aynı kelime iki kez girilmez
    // neden #Unique yerine composite key string: SwiftData composite unique
    // desteği sınırlı; tek alanlı benzersiz anahtar sorguyu da basitleştirir
    @Attribute(.unique) var key: String
    var chapterId: String
    var wordId: Int
    var isLearned: Bool
    var correctCount: Int
    var wrongCount: Int

    init(chapterId: String, wordId: Int, isLearned: Bool, correctCount: Int, wrongCount: Int) {
        self.key = Self.makeKey(chapterId: chapterId, wordId: wordId)
        self.chapterId = chapterId
        self.wordId = wordId
        self.isLearned = isLearned
        self.correctCount = correctCount
        self.wrongCount = wrongCount
    }

    static func makeKey(chapterId: String, wordId: Int) -> String {
        "\(chapterId)#\(wordId)"
    }

    var asEntity: WordProgress {
        WordProgress(
            chapterId: chapterId,
            wordId: wordId,
            isLearned: isLearned,
            correctCount: correctCount,
            wrongCount: wrongCount
        )
    }
}
