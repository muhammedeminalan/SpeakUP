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
            // neden geometri tabanlı swipe: Flutter'daki kart kaydırma hissi korunur
            let displayed = history.historyItem ?? question

            WordQuizQuestionView(
                state: displayed,
                isReadOnly: history.isInHistory,
                onSelect: { viewModel.selectAnswer($0) },
                onNext: { goForward() }
            )
            .id("\(history.isInHistory ? history.historyItem?.questionIndex ?? -1 : question.questionIndex)_\(history.isInHistory)")
            .offset(x: dragOffset)
            .rotationEffect(
                .radians(Double(min(max(dragOffset / max(UIScreen.main.bounds.width, 1), -1), 1)) * 0.05),
                anchor: .bottom
            )
            .animation(.easeOut(duration: 0.18), value: history.isInHistory)
            .gesture(swipeGesture)
        } else {
            // Başlatma anı — Flutter'daki Initial state'in karşılığı
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let screenWidth = UIScreen.main.bounds.width
                let farEnough = abs(dragOffset) > screenWidth * 0.33
                let fastEnough = abs(value.predictedEndTranslation.width - value.translation.width) > 200

                if dragOffset < 0, farEnough || fastEnough, canGoForward {
                    dragOffset = 0
                    goForward()
                } else if dragOffset > 0, farEnough || fastEnough, history.canGoBack {
                    dragOffset = 0
                    history.goBack()
                } else {
                    // Eşik aşılmadı — kart yerine geri yaylanır
                    withAnimation(.spring(duration: 0.42)) { dragOffset = 0 }
                }
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
