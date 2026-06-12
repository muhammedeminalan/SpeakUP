import Foundation

// Soyut arayüz — JSON veya ileride uzak kaynak implementasyonu buraya bağlanır
protocol ChapterRepository {
    func getChapters() async throws -> [Chapter]
}
