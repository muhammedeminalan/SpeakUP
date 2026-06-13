import Foundation
import SwiftData

final class WordProgressRepositoryImpl: WordProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [WordProgress] {
        do {
            let records = try context.fetch(
                FetchDescriptor<WordProgressRecord>()
            )
            return records.map(\.asEntity)
        } catch {
            throw AppFailure.storage(
                "Kelime ilerlemesi okunamadı: \(error.localizedDescription)"
            )
        }
    }

    func getById(chapterId: String, wordId: Int) throws -> WordProgress? {
        try fetchRecord(chapterId: chapterId, wordId: wordId)?.asEntity
    }

    func upsert(_ progress: WordProgress) throws {
        do {
            if let existing = try fetchRecord(
                chapterId: progress.chapterId,
                wordId: progress.wordId
            ) {
                existing.isLearned = progress.isLearned
                existing.correctCount = progress.correctCount
                existing.wrongCount = progress.wrongCount
            } else {
                context.insert(
                    WordProgressRecord(
                        chapterId: progress.chapterId,
                        wordId: progress.wordId,
                        isLearned: progress.isLearned,
                        correctCount: progress.correctCount,
                        wrongCount: progress.wrongCount
                    )
                )
            }
            try context.save()
        } catch {
            throw AppFailure.storage(
                "Kelime ilerlemesi kaydedilemedi: \(error.localizedDescription)"
            )
        }
    }

    private func fetchRecord(chapterId: String, wordId: Int) throws
        -> WordProgressRecord?
    {
        let key = WordProgressRecord.makeKey(
            chapterId: chapterId,
            wordId: wordId
        )
        var descriptor = FetchDescriptor<WordProgressRecord>(
            predicate: #Predicate { $0.key == key }
        )
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw AppFailure.storage(
                "Kelime ilerlemesi sorgulanamadı: \(error.localizedDescription)"
            )
        }
    }
}
