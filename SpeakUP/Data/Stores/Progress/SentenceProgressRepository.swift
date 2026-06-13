import Foundation

protocol SentenceProgressRepository {
    func getAll() throws -> [SentenceProgress]
    func getById(chapterId: String, sentenceId: Int) throws -> SentenceProgress?
    func upsert(_ progress: SentenceProgress) throws
}
