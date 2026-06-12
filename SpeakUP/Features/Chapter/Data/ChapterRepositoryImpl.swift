import Foundation

struct ChapterRepositoryImpl: ChapterRepository {
    private let dataSource: JsonChapterDataSource

    init(dataSource: JsonChapterDataSource) {
        self.dataSource = dataSource
    }

    func getChapters() async throws -> [Chapter] {
        do {
            return try dataSource.getChapters()
        } catch let failure as AppFailure {
            throw failure
        } catch {
            throw AppFailure.data("Bölümler yüklenemedi: \(error.localizedDescription)")
        }
    }
}
