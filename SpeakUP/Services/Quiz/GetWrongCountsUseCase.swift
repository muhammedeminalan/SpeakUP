import Foundation

/// Belirli bir bölüme ait yanlış cevap sayılarını döner.
/// neden: ViewModel repository'ye doğrudan bağımlı olmasın; UseCase katmanı korunur
struct GetWrongCountsUseCase {
    private let repository: WordProgressRepository

    init(repository: WordProgressRepository) {
        self.repository = repository
    }

    func callAsFunction(chapterId: String) -> [Int: Int] {
        // Hata durumunda boş map — ağırlıklı seçim devre dışı kalır, quiz yine çalışır
        guard let list = try? repository.getAll() else { return [:] }
        return Dictionary(
            uniqueKeysWithValues: list
                .filter { $0.chapterId == chapterId }
                .map { ($0.wordId, $0.wrongCount) }
        )
    }
}
