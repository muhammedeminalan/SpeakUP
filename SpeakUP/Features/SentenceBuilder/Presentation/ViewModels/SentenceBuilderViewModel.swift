import Foundation

/// Cümle kurma akışını yöneten ViewModel — Flutter'daki SentenceBuilderBloc + Runtime
@Observable
final class SentenceBuilderViewModel {
    struct Finished {
        let chapterId: String
        let allSentences: [Sentence]
        let wrongSentenceIds: [Int]
        let attemptedSentenceIds: [Int]
        let correctCount: Int
        let totalQuestions: Int
        let xpEarned: Int
        let sentenceResults: [SentenceResult]
    }

    // ── Yayınlanan durum ───────────────────────────────────────────────────
    private(set) var question: SentenceQuestionState?
    private(set) var finished: Finished?

    // ── Çalışma durumu ─────────────────────────────────────────────────────
    private(set) var chapterId = ""
    private var allSentences: [Sentence] = []
    private var questionCount = -1
    private var sentences: [Sentence] = []
    private var currentIndex = 0
    private var correctCount = 0
    private var wrongCount = 0
    private var wrongSentenceIds: [Int] = []
    private var sentenceResults: [SentenceResult] = []
    private var direction: QuizDirection = .trToEn

    // ── Bağımlılıklar ──────────────────────────────────────────────────────
    private let getSentences: GetSentencesUseCase
    private let saveProgress: SaveSentenceProgressUseCase

    init(getSentences: GetSentencesUseCase, saveProgress: SaveSentenceProgressUseCase) {
        self.getSentences = getSentences
        self.saveProgress = saveProgress
    }

    // ── Başlatma ───────────────────────────────────────────────────────────

    func start(chapterId: String, sentences: [Sentence], questionCount: Int, direction: QuizDirection) {
        self.chapterId = chapterId
        self.allSentences = sentences
        self.questionCount = questionCount
        self.direction = direction

        let all = getSentences(sentences)
        // questionCount == -1 ise tümünü al, değilse kırp
        self.sentences = questionCount == -1
            ? all
            : Array(all.prefix(min(max(questionCount, 1), all.count)))

        currentIndex = 0
        correctCount = 0
        wrongCount = 0
        wrongSentenceIds = []
        sentenceResults = []

        // Boş liste guard: hemen biter, crash olmaz
        if self.sentences.isEmpty {
            emitFinished()
            return
        }
        emitQuestion()
    }

    /// Yarıda bırakılan oturumdan devam
    func resume(from session: SentenceBuilderSession) {
        chapterId = session.chapterId
        allSentences = session.allSentences
        questionCount = session.questionCount
        sentences = session.questions
        currentIndex = min(max(session.currentIndex, 0), max(session.questions.count - 1, 0))
        correctCount = session.correctCount
        wrongCount = session.wrongCount
        wrongSentenceIds = session.wrongSentenceIds
        sentenceResults = []

        guard !sentences.isEmpty else {
            emitFinished()
            return
        }

        question = SentenceQuestionState(
            chapterId: chapterId,
            sentence: sentences[currentIndex],
            availableWords: session.availableWords,
            placedWords: session.placedWords,
            questionIndex: currentIndex,
            totalQuestions: sentences.count,
            correctCount: correctCount,
            wrongCount: wrongCount,
            direction: direction,
            isChecked: session.isChecked,
            isCorrect: session.isCorrect
        )
    }

    // ── Etkileşimler ───────────────────────────────────────────────────────

    func dropWord(_ word: String) {
        guard var current = question, !current.isChecked else { return }
        guard let index = current.availableWords.firstIndex(of: word) else { return }
        current.availableWords.remove(at: index)
        current.placedWords.append(word)
        question = current

        // neden: tüm kelimeler alınınca kullanıcıyı bekletmeden otomatik kontrol eder
        if current.availableWords.isEmpty {
            checkAnswer()
        }
    }

    func removeWord(_ word: String) {
        guard var current = question, !current.isChecked else { return }
        guard let index = current.placedWords.firstIndex(of: word) else { return }
        current.placedWords.remove(at: index)
        current.availableWords.append(word)
        question = current
    }

    func checkAnswer() {
        guard var current = question, !current.isChecked else { return }

        let userAnswer = normalizeForCompare(current.placedWords.joined(separator: " "))
        // neden: yöne göre doğru cevap İngilizce ya da Türkçe cümle olabilir
        let correctAnswer = normalizeForCompare(current.answerText)
        let isCorrect = userAnswer == correctAnswer

        let result = SentenceResult(
            sentence: current.sentence,
            userAnswer: current.placedWords.joined(separator: " "),
            isCorrect: isCorrect
        )
        sentenceResults.append(result)

        if isCorrect {
            correctCount += 1
        } else {
            wrongCount += 1
            if !wrongSentenceIds.contains(current.sentence.id) {
                wrongSentenceIds.append(current.sentence.id)
            }
        }

        // Progress'i kalıcı depoya yaz — hata olsa da quiz akışını durdurmuyoruz
        var warningMessage: String?
        do {
            try saveProgress(chapterId: chapterId, sentenceId: current.sentence.id, isCorrect: isCorrect)
        } catch {
            warningMessage = "İlerleme kaydedilemedi: \(error.localizedDescription)"
        }

        current.isChecked = true
        current.isCorrect = isCorrect
        current.correctCount = correctCount
        current.wrongCount = wrongCount
        current.warningMessage = warningMessage
        question = current
    }

    func nextQuestion() {
        guard finished == nil else { return }
        currentIndex += 1
        if currentIndex >= sentences.count {
            emitFinished()
        } else {
            emitQuestion()
        }
    }

    // ── Oturum kaydetme — "Ara Ver" ────────────────────────────────────────

    func makeSession() -> SentenceBuilderSession? {
        guard let current = question, finished == nil else { return nil }
        return SentenceBuilderSession(
            chapterId: chapterId,
            allSentences: allSentences,
            questionCount: questionCount,
            questions: sentences,
            currentIndex: currentIndex,
            correctCount: correctCount,
            wrongCount: wrongCount,
            placedWords: current.placedWords,
            availableWords: current.availableWords,
            isChecked: current.isChecked,
            isCorrect: current.isCorrect,
            wrongSentenceIds: wrongSentenceIds
        )
    }

    // ── Yardımcılar ────────────────────────────────────────────────────────

    private func emitQuestion() {
        let sentence = sentences[currentIndex]
        question = SentenceQuestionState(
            chapterId: chapterId,
            sentence: sentence,
            availableWords: getSentences.shuffledWords(for: sentence, direction: direction),
            placedWords: [],
            questionIndex: currentIndex,
            totalQuestions: sentences.count,
            correctCount: correctCount,
            wrongCount: wrongCount,
            direction: direction
        )
    }

    private func emitFinished() {
        question = nil
        finished = Finished(
            chapterId: chapterId,
            allSentences: allSentences,
            wrongSentenceIds: wrongSentenceIds,
            attemptedSentenceIds: sentences.map(\.id),
            correctCount: correctCount,
            totalQuestions: sentences.count,
            // Cümle kurmak kelime quizinden daha çok XP verir
            xpEarned: correctCount * 15,
            sentenceResults: sentenceResults
        )
    }

    // neden: karşılaştırma kuralı tek yerde kalırsa yanlış/eksik normalize bug'u azalır
    private func normalizeForCompare(_ text: String) -> String {
        text
            .replacingOccurrences(of: "[.,!?]", with: "", options: .regularExpression)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
