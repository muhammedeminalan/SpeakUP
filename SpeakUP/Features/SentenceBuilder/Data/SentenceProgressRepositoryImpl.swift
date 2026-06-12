import Foundation
import SwiftData

final class SentenceProgressRepositoryImpl: SentenceProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [SentenceProgress] {
        do {
            let records = try context.fetch(FetchDescriptor<SentenceProgressRecord>())
            return records.map(\.asEntity)
        } catch {
            throw AppFailure.storage("Cümle ilerlemesi okunamadı: \(error.localizedDescription)")
        }
    }

    func getById(chapterId: String, sentenceId: Int) throws -> SentenceProgress? {
        try fetchRecord(chapterId: chapterId, sentenceId: sentenceId)?.asEntity
    }

    func upsert(_ progress: SentenceProgress) throws {
        do {
            if let existing = try fetchRecord(chapterId: progress.chapterId, sentenceId: progress.sentenceId) {
                existing.isLearned = progress.isLearned
                existing.correctCount = progress.correctCount
                existing.wrongCount = progress.wrongCount
            } else {
                context.insert(SentenceProgressRecord(
                    chapterId: progress.chapterId,
                    sentenceId: progress.sentenceId,
                    isLearned: progress.isLearned,
                    correctCount: progress.correctCount,
                    wrongCount: progress.wrongCount
                ))
            }
            try context.save()
        } catch {
            throw AppFailure.storage("Cümle ilerlemesi kaydedilemedi: \(error.localizedDescription)")
        }
    }

    private func fetchRecord(chapterId: String, sentenceId: Int) throws -> SentenceProgressRecord? {
        let key = SentenceProgressRecord.makeKey(chapterId: chapterId, sentenceId: sentenceId)
        var descriptor = FetchDescriptor<SentenceProgressRecord>(
            predicate: #Predicate { $0.key == key }
        )
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw AppFailure.storage("Cümle ilerlemesi sorgulanamadı: \(error.localizedDescription)")
        }
    }
}
