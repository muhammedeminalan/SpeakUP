import Foundation

protocol WordProgressRepository {
    func getAll() throws -> [WordProgress]
    func getById(chapterId: String, wordId: Int) throws -> WordProgress?
    func upsert(_ progress: WordProgress) throws
}
