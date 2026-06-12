import Foundation

/// Bölüm ilerleme ekranının ViewModel'i — kelime + cümle istatistikleri
@Observable
final class ProgressViewModel {
    enum State {
        case loading
        case error(String)
        case data
    }

    private(set) var state: State = .loading

    // ── Kelime ─────────────────────────────────────────────────────────────
    private(set) var words: [Word] = []
    private(set) var progressMap: [Int: WordProgress] = [:]

    // neden sadece attemptedWords: kaydı olmayan kelime hiç quiz görmemiş
    var attemptedWords: [Word] { words.filter { progressMap[$0.id] != nil } }
    var learnedWords: [Word] { attemptedWords.filter { progressMap[$0.id]?.isLearned == true } }
    var retryWords: [Word] { attemptedWords.filter { progressMap[$0.id]?.isLearned == false } }
    var notStartedCount: Int { words.count - attemptedWords.count }
    var completionRatio: Double {
        words.isEmpty ? 0 : Double(learnedWords.count) / Double(words.count)
    }

    // ── Cümle ──────────────────────────────────────────────────────────────
    private(set) var sentences: [Sentence] = []
    private(set) var sentenceProgressMap: [Int: SentenceProgress] = [:]

    var attemptedSentences: [Sentence] { sentences.filter { sentenceProgressMap[$0.id] != nil } }
    var learnedSentences: [Sentence] { attemptedSentences.filter { sentenceProgressMap[$0.id]?.isLearned == true } }
    var retrySentences: [Sentence] { attemptedSentences.filter { sentenceProgressMap[$0.id]?.isLearned == false } }
    var notStartedSentenceCount: Int { sentences.count - attemptedSentences.count }
    var sentenceCompletionRatio: Double {
        sentences.isEmpty ? 0 : Double(learnedSentences.count) / Double(sentences.count)
    }

    private(set) var chapterId = ""

    // ── Bağımlılıklar ──────────────────────────────────────────────────────
    // neden iki repository: kelime ve cümle progress ayrı kayıt tiplerinde
    private let wordRepository: WordProgressRepository
    private let sentenceRepository: SentenceProgressRepository

    init(wordRepository: WordProgressRepository, sentenceRepository: SentenceProgressRepository) {
        self.wordRepository = wordRepository
        self.sentenceRepository = sentenceRepository
    }

    func load(chapterId: String, words: [Word], sentences: [Sentence]) {
        state = .loading
        self.chapterId = chapterId
        self.words = words
        self.sentences = sentences

        do {
            let wordProgressList = try wordRepository.getAll()
            let sentenceProgressList = try sentenceRepository.getAll()

            // Sadece bu bölüme ait kayıtları filtrele
            progressMap = Dictionary(
                uniqueKeysWithValues: wordProgressList
                    .filter { $0.chapterId == chapterId }
                    .map { ($0.wordId, $0) }
            )
            sentenceProgressMap = Dictionary(
                uniqueKeysWithValues: sentenceProgressList
                    .filter { $0.chapterId == chapterId }
                    .map { ($0.sentenceId, $0) }
            )
            state = .data
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
