import Foundation

struct GetChaptersUseCase {
    private let repository: ChapterRepository

    init(repository: ChapterRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [Chapter] {
        try await repository.getChapters()
    }
}
