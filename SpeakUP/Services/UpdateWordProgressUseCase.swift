import Foundation

struct UpdateWordProgressUseCase {
    private let repository: WordProgressRepository

    init(repository: WordProgressRepository) {
        self.repository = repository
    }

    func callAsFunction(chapterId: String, wordId: Int, wasCorrect: Bool, isLearned: Bool) throws {
        let existing = try repository.getById(chapterId: chapterId, wordId: wordId)

        try repository.upsert(WordProgress(
            chapterId: chapterId,
            wordId: wordId,
            // neden: bir kez öğrenildi ise yanlış cevap bayrağı sıfırlamamalı —
            // SaveSentenceProgressUseCase ile tutarlı davranış; motivasyon korunur
            isLearned: existing?.isLearned == true ? true : isLearned,
            correctCount: (existing?.correctCount ?? 0) + (wasCorrect ? 1 : 0),
            wrongCount: (existing?.wrongCount ?? 0) + (wasCorrect ? 0 : 1)
        ))
    }
}
