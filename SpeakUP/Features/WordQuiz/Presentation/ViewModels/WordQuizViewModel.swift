import Foundation

/// Kelime quizi akışını yöneten ViewModel — Flutter'daki WordQuizBloc + Runtime.
/// neden tek sınıf: bloc/event/state/factory dörtlüsü Swift'te @Observable ile
/// sadeleşir; aynı determinizm korunur, dosya sayısı yapay olarak şişmez.
@Observable
final class WordQuizViewModel {
    /// Quiz bittiğinde sonuç ekranına taşınacak veri
    struct Finished {
        let chapterId: String
        let chapterWords: [Word]
        let wrongWordIds: [Int]
        let attemptedWordIds: [Int]
        let correctCount: Int
        let totalQuestions: Int
        let xpEarned: Int
        let wrongAnswerDetails: [WrongAnswerDetail]
        let correctWords: [Word]
        let direction: QuizDirection
    }

    // ── Yayınlanan durum ───────────────────────────────────────────────────
    private(set) var question: WordQuizQuestionState?
    private(set) var finished: Finished?

    // ── Quiz çalışma durumu (Flutter'daki WordQuizRuntime) ─────────────────
    private(set) var chapterId = ""
    private var chapterWords: [Word] = []
    private var optionPool: [Word] = []
    private var settings = QuizSettings(questionCount: -1)
    private var questions: [Word] = []
    private var currentIndex = 0
    private var correctCount = 0
    private var wrongCount = 0
    private var wrongWordIds: [Int] = []
    private var wrongAnswerDetails: [WrongAnswerDetail] = []
    private var correctWords: [Word] = []

    // ── Bağımlılıklar ──────────────────────────────────────────────────────
    private let getWords: GetWordsForQuizUseCase
    private let updateProgress: UpdateWordProgressUseCase
    private let getWrongCounts: GetWrongCountsUseCase

    init(
        getWords: GetWordsForQuizUseCase,
        updateProgress: UpdateWordProgressUseCase,
        getWrongCounts: GetWrongCountsUseCase
    ) {
        self.getWords = getWords
        self.updateProgress = updateProgress
        self.getWrongCounts = getWrongCounts
    }

    // ── Başlatma ───────────────────────────────────────────────────────────

    func start(chapterId: String, words: [Word], settings: QuizSettings, optionPool: [Word]?) {
        self.chapterId = chapterId
        self.chapterWords = words
        // neden ayrı havuz: retry modunda sorular daralsa da şıklar tam
        // bölüm havuzundan üretilir — hep 4 seçenek olur
        self.optionPool = optionPool ?? words
        self.settings = settings

        let count = settings.resolveCount(available: words.count)
        let wrongCounts = getWrongCounts(chapterId: chapterId)
        questions = getWords(words, count: count, wrongCounts: wrongCounts)
        currentIndex = 0
        correctCount = 0
        wrongCount = 0
        wrongWordIds = []
        wrongAnswerDetails = []
        correctWords = []

        // Boş liste guard: hemen biter, crash olmaz
        if questions.isEmpty {
            emitFinished()
            return
        }
        emitCurrentQuestion()
    }

    /// Yarıda bırakılan oturumdan devam — kaydedilmiş şıklar ve seçim geri gelir
    func resume(from session: WordQuizSession) {
        chapterId = session.chapterId
        chapterWords = session.chapterWords
        optionPool = session.chapterWords
        settings = session.settings
        questions = session.questions
        currentIndex = min(max(session.currentIndex, 0), max(session.questions.count - 1, 0))
        correctCount = session.correctCount
        wrongCount = session.wrongCount
        wrongWordIds = session.wrongWordIds
        wrongAnswerDetails = []
        correctWords = []

        guard !questions.isEmpty else {
            emitFinished()
            return
        }

        question = WordQuizQuestionState(
            chapterId: chapterId,
            currentWord: questions[currentIndex],
            options: session.currentOptions,
            questionIndex: currentIndex,
            totalQuestions: questions.count,
            correctCount: correctCount,
            wrongCount: wrongCount,
            selectedAnswer: session.selectedAnswer,
            isAnswered: session.isAnswered,
            direction: settings.direction
        )
    }

    // ── Etkileşimler ───────────────────────────────────────────────────────

    func selectAnswer(_ answer: String) {
        guard var current = question, !current.isAnswered else { return }

        let isCorrect = answer == current.correctAnswer

        if isCorrect {
            correctCount += 1
            correctWords.append(current.currentWord)
        } else {
            wrongCount += 1
            if !wrongWordIds.contains(current.currentWord.id) {
                wrongWordIds.append(current.currentWord.id)
            }
            wrongAnswerDetails.append(WrongAnswerDetail(
                word: current.currentWord,
                selectedAnswer: answer,
                direction: settings.direction
            ))
        }

        // Progress'i kalıcı depoya yaz — hata olsa da quiz akışını durdurmuyoruz
        var warningMessage: String?
        do {
            try updateProgress(
                chapterId: chapterId,
                wordId: current.currentWord.id,
                wasCorrect: isCorrect,
                isLearned: isCorrect
            )
        } catch {
            warningMessage = "İlerleme kaydedilemedi: \(error.localizedDescription)"
        }

        current.selectedAnswer = answer
        current.isAnswered = true
        current.warningMessage = warningMessage
        question = WordQuizQuestionState(
            chapterId: current.chapterId,
            currentWord: current.currentWord,
            options: current.options,
            questionIndex: current.questionIndex,
            totalQuestions: current.totalQuestions,
            correctCount: correctCount,
            wrongCount: wrongCount,
            selectedAnswer: answer,
            isAnswered: true,
            warningMessage: warningMessage,
            direction: current.direction
        )
    }

    func nextQuestion() {
        guard finished == nil else { return }
        currentIndex += 1
        if currentIndex >= questions.count {
            emitFinished()
        } else {
            emitCurrentQuestion()
        }
    }

    // ── Oturum kaydetme — "Ara Ver" ────────────────────────────────────────

    func makeSession() -> WordQuizSession? {
        guard let current = question, finished == nil else { return nil }
        return WordQuizSession(
            chapterId: chapterId,
            chapterWords: chapterWords,
            settings: settings,
            questions: questions,
            currentIndex: currentIndex,
            correctCount: correctCount,
            wrongCount: wrongCount,
            isAnswered: current.isAnswered,
            selectedAnswer: current.selectedAnswer,
            currentOptions: current.options,
            wrongWordIds: wrongWordIds
        )
    }

    // ── Yardımcılar ────────────────────────────────────────────────────────

    private func emitCurrentQuestion() {
        let word = questions[currentIndex]
        let options = getWords.generateOptions(for: word, from: optionPool, direction: settings.direction)
        question = WordQuizQuestionState(
            chapterId: chapterId,
            currentWord: word,
            options: options,
            questionIndex: currentIndex,
            totalQuestions: questions.count,
            correctCount: correctCount,
            wrongCount: wrongCount,
            direction: settings.direction
        )
    }

    private func emitFinished() {
        question = nil
        finished = Finished(
            chapterId: chapterId,
            chapterWords: chapterWords,
            wrongWordIds: wrongWordIds,
            attemptedWordIds: questions.map(\.id),
            correctCount: correctCount,
            totalQuestions: questions.count,
            // Her doğru cevap 10 XP
            xpEarned: correctCount * 10,
            wrongAnswerDetails: wrongAnswerDetails,
            correctWords: correctWords,
            direction: settings.direction
        )
    }
}
