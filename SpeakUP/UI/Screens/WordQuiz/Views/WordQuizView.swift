import SwiftUI

/// Kelime quizi ekranı — swipe ile geçmiş sorulara dönme destekli
struct WordQuizView: View {
    let payload: WordQuizPayload

    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps
    @Environment(AppSettings.self) private var settings

    @State private var viewModel: WordQuizViewModel?
    @State private var history = QuizHistory<WordQuizQuestionState>()

    // ── Swipe durumu ───────────────────────────────────────────────────────
    @State private var dragOffset: CGFloat = 0
    /// -1 = sola (ileri), +1 = sağa (geri) — transition yönünü belirler
    @State private var swipeDir: Int = 0
    @State private var showExitConfirm = false
    @State private var showOptions = false

    var body: some View {
        VStack(spacing: 0) {
            GradientNavBar(
                title: navTitle,
                onBack: { showExitConfirm = true }
            ) {
                if viewModel?.question != nil {
                    Button { showOptions = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
            }

            content
        }
        .background(AppTheme.surface)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: setupIfNeeded)
        .onChange(of: viewModel?.question) { _, newQuestion in
            guard let newQuestion else { return }
            // cevap verildi → snapshot beklet; yeni soru geldi → history'e taşı
            if newQuestion.isAnswered {
                history.onAnswered(newQuestion)
            } else {
                history.onNewQuestion()
            }
        }
        .onChange(of: viewModel?.finished != nil) { _, isFinished in
            guard isFinished, let result = viewModel?.finished else { return }
            navigateToResult(result)
        }
        .sheet(isPresented: $showExitConfirm) {
            QuizExitConfirmSheet {
                // Çıkış onaylandı — yarım oturum silinir
                deps.sessionStore.clearWordSession(chapterId: viewModel?.chapterId)
                router.pop()
            }
        }
        .sheet(isPresented: $showOptions) {
            QuizOptionsSheet(onPause: pauseAndExit)
        }
    }

    private var navTitle: String {
        guard let question = viewModel?.question else { return "Kelime Quiz" }
        return "\(question.questionIndex + 1) / \(question.totalQuestions)"
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel, let question = viewModel.question {
            let displayed = history.historyItem ?? question

            // ZStack dragOffset'i taşır; içindeki kart transition ile girer/çıkar.
            // neden ZStack: offset + kart transition birbirini ezmeden çalışır
            ZStack {
                WordQuizQuestionView(
                    state: displayed,
                    isReadOnly: history.isInHistory,
                    onSelect: { viewModel.selectAnswer($0) },
                    onNext: { commitSwipe(direction: -1) }
                )
                .id(cardId)
                .transition(.asymmetric(
                    insertion: .move(edge: swipeDir < 0 ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .move(edge: swipeDir < 0 ? .leading : .trailing)
                        .combined(with: .opacity)
                ))
            }
            .offset(x: dragOffset)
            .rotationEffect(
                .radians(Double(min(max(dragOffset / max(UIScreen.main.bounds.width, 1), -1), 1)) * 0.05),
                anchor: .bottom
            )
            .gesture(swipeGesture)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var cardId: String {
        guard let viewModel, let question = viewModel.question else { return "empty" }
        let displayed = history.historyItem ?? question
        return "\(displayed.questionIndex)_\(history.isInHistory)"
    }

    // ── Kurulum ────────────────────────────────────────────────────────────

    private func setupIfNeeded() {
        guard viewModel == nil else { return }

        // neden: quiz yönüne göre TTS aksanı otomatik ayarla
        settings.autoSelectAccent(promptIsTurkish: payload.settings.direction == .trToEn)

        let vm = WordQuizViewModel(
            getWords: deps.getWordsForQuiz,
            updateProgress: deps.updateWordProgress,
            getWrongCounts: deps.getWrongCounts
        )
        if payload.resume, let session = deps.sessionStore.wordSession(forChapter: payload.chapterId) {
            vm.resume(from: session)
        } else {
            vm.start(
                chapterId: payload.chapterId,
                words: payload.words,
                settings: payload.settings,
                optionPool: payload.optionPool
            )
        }
        viewModel = vm
    }

    // ── Navigasyon ─────────────────────────────────────────────────────────

    private func pauseAndExit() {
        guard let viewModel, let session = viewModel.makeSession() else {
            router.pop()
            return
        }
        deps.sessionStore.saveWordSession(session)
        router.pop()
    }

    private func navigateToResult(_ result: WordQuizViewModel.Finished) {
        deps.sessionStore.clearWordSession(chapterId: result.chapterId)
        router.replace(with: .wordQuizResult(WordQuizResultPayload(
            chapterId: result.chapterId,
            chapterWords: result.chapterWords,
            wrongWordIds: result.wrongWordIds,
            attemptedWordIds: result.attemptedWordIds,
            defaultQuestionCount: result.totalQuestions,
            correct: result.correctCount,
            total: result.totalQuestions,
            xpEarned: result.xpEarned,
            wrongAnswerDetails: result.wrongAnswerDetails,
            correctWords: result.correctWords,
            direction: result.direction
        )))
    }

    // ── Swipe ──────────────────────────────────────────────────────────────

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation.width }
            .onEnded { value in
                let w = UIScreen.main.bounds.width
                let farEnough = abs(dragOffset) > w * 0.30
                // iOS 17+ velocity API — hız bazlı hızlı fırlatma tespiti
                let fastEnough = abs(value.velocity.width) > 500

                if dragOffset < 0, farEnough || fastEnough, canGoForward {
                    commitSwipe(direction: -1)
                } else if dragOffset > 0, farEnough || fastEnough, history.canGoBack {
                    commitSwipe(direction: 1)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dragOffset = 0 }
                }
            }
    }

    /// Swipe geçişini uygular — yön belirlenip offset sıfırlanır, ardından
    /// withAnimation içinde state değişir ve transition tetiklenir.
    private func commitSwipe(direction: Int) {
        swipeDir = direction
        dragOffset = 0
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            if direction < 0 { goForward() } else { history.goBack() }
        }
    }

    private var canGoForward: Bool {
        if history.isInHistory { return true }
        return viewModel?.question?.isAnswered == true
    }

    private func goForward() {
        if history.isInHistory {
            history.goForwardInHistory()
        } else if viewModel?.question?.isAnswered == true {
            viewModel?.nextQuestion()
        }
    }
}
