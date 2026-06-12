import Foundation
import SwiftData

/// Bağımlılık konteyneri — Flutter'daki get_it injection.dart karşılığı.
/// neden tek sınıf: tüm servis/usecase kurulumu tek yerden, test'te sahteleri
/// ile değiştirilebilir; SwiftUI Environment üzerinden alt görünümlere iner.
// neden @Observable: SwiftUI Environment yalnızca Observable nesneleri taşır;
// içerik değişmez ama Environment(AppDependencies.self) erişimi bunu gerektirir
@Observable
@MainActor
final class AppDependencies {
    // ── Servisler (singleton) ──────────────────────────────────────────────
    let tts: TTSService
    let settings: AppSettings
    let sessionStore: QuizSessionStore
    let retryWordSetBuilder = RetryWordSetBuilder()

    // ── Storage ────────────────────────────────────────────────────────────
    let modelContainer: ModelContainer

    // ── Repositories ───────────────────────────────────────────────────────
    let chapterRepository: ChapterRepository
    let wordProgressRepository: WordProgressRepository
    let sentenceProgressRepository: SentenceProgressRepository

    // ── Use case'ler ───────────────────────────────────────────────────────
    let getChapters: GetChaptersUseCase
    let getWordsForQuiz = GetWordsForQuizUseCase()
    let updateWordProgress: UpdateWordProgressUseCase
    let getWrongCounts: GetWrongCountsUseCase
    let getSentences = GetSentencesUseCase()
    let saveSentenceProgress: SaveSentenceProgressUseCase

    init() throws {
        // TTS önce kurulur — AppSettings kaydedilmiş tercihleri ona uygular
        let tts = TTSService()
        self.tts = tts
        self.settings = AppSettings(tts: tts)
        self.sessionStore = QuizSessionStore()

        // neden iki model tek container: aynı store dosyasında ayrı tablolar —
        // Flutter'daki iki ayrı sqflite DB'nin sadeleştirilmiş karşılığı
        self.modelContainer = try ModelContainer(
            for: WordProgressRecord.self, SentenceProgressRecord.self
        )
        let context = modelContainer.mainContext

        self.chapterRepository = ChapterRepositoryImpl(dataSource: JsonChapterDataSource())
        self.wordProgressRepository = WordProgressRepositoryImpl(context: context)
        self.sentenceProgressRepository = SentenceProgressRepositoryImpl(context: context)

        self.getChapters = GetChaptersUseCase(repository: chapterRepository)
        self.updateWordProgress = UpdateWordProgressUseCase(repository: wordProgressRepository)
        self.getWrongCounts = GetWrongCountsUseCase(repository: wordProgressRepository)
        self.saveSentenceProgress = SaveSentenceProgressUseCase(repository: sentenceProgressRepository)
    }
}
