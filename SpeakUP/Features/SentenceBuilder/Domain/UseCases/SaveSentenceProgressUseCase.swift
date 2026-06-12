import Foundation

/// Her cümle cevaplandıktan sonra kalıcı depoya yazılır.
/// neden ayrı UseCase: ViewModel doğrudan repository'ye bağımlı olmaz
struct SaveSentenceProgressUseCase {
    private let repository: SentenceProgressRepository

    init(repository: SentenceProgressRepository) {
        self.repository = repository
    }

    func callAsFunction(chapterId: String, sentenceId: Int, isCorrect: Bool) throws {
        let existing = try repository.getById(chapterId: chapterId, sentenceId: sentenceId)

        try repository.upsert(SentenceProgress(
            chapterId: chapterId,
            sentenceId: sentenceId,
            // neden isLearned sadece true'ya geçer: bir kere doğru cevaplandı mı
            // öğrenildi sayılır; sonraki yanlış cevap sıfırlamaz
            isLearned: existing?.isLearned == true ? true : isCorrect,
            correctCount: (existing?.correctCount ?? 0) + (isCorrect ? 1 : 0),
            wrongCount: (existing?.wrongCount ?? 0) + (isCorrect ? 0 : 1)
        ))
    }
}
