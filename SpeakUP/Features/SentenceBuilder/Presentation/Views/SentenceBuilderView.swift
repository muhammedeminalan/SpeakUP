import SwiftUI

/// Cümle kurma ekranı — kelimelere tıklayarak cümle dizilir
struct SentenceBuilderView: View {
    let payload: SentenceBuilderPayload

    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps
    @Environment(AppSettings.self) private var settings

    @State private var viewModel: SentenceBuilderViewModel?
    @State private var history = QuizHistory<SentenceQuestionState>()

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
            if newQuestion.isChecked {
                history.onAnswered(newQuestion)
            } else if newQuestion.placedWords.isEmpty {
                // neden placedWords kontrolü: kelime taşıma güncellemeleri yeni soru sayılmasın
                history.onNewQuestion()
            }
        }
        .onChange(of: viewModel?.finished != nil) { _, isFinished in
            guard isFinished, let result = viewModel?.finished else { return }
            navigateToResult(result)
        }
        .sheet(isPresented: $showExitConfirm) {
            QuizExitConfirmSheet {
                deps.sessionStore.clearSentenceSession(chapterId: viewModel?.chapterId)
                router.pop()
            }
        }
        .sheet(isPresented: $showOptions) {
            QuizOptionsSheet(onPause: pauseAndExit)
        }
    }

    private var navTitle: String {
        guard let question = viewModel?.question else { return "Cümle Kur" }
        return "\(question.questionIndex + 1) / \(question.totalQuestions)"
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel, let question = viewModel.question {
            let displayed = history.historyItem ?? question

            SentenceBuilderQuestionView(
                state: displayed,
                isReadOnly: history.isInHistory,
                onDrop: { viewModel.dropWord($0) },
                onRemove: { viewModel.removeWord($0) },
                onCheck: { viewModel.checkAnswer() },
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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // ── Kurulum ────────────────────────────────────────────────────────────

    private func setupIfNeeded() {
        guard viewModel == nil else { return }

        // neden: quiz yönüne göre TTS aksanı otomatik ayarla
        settings.autoSelectAccent(promptIsTurkish: payload.direction == .trToEn)

        let vm = SentenceBuilderViewModel(
            getSentences: deps.getSentences,
            saveProgress: deps.saveSentenceProgress
        )
        if payload.resume, let session = deps.sessionStore.sentenceSession(forChapter: payload.chapterId) {
            vm.resume(from: session)
        } else {
            vm.start(
                chapterId: payload.chapterId,
                sentences: payload.sentences,
                questionCount: payload.questionCount,
                direction: payload.direction
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
        deps.sessionStore.saveSentenceSession(session)
        router.pop()
    }

    private func navigateToResult(_ result: SentenceBuilderViewModel.Finished) {
        deps.sessionStore.clearSentenceSession(chapterId: result.chapterId)
        router.replace(with: .sentenceResult(SentenceResultPayload(
            chapterId: result.chapterId,
            allSentences: result.allSentences,
            wrongSentenceIds: result.wrongSentenceIds,
            attemptedSentenceIds: result.attemptedSentenceIds,
            defaultQuestionCount: result.totalQuestions,
            correct: result.correctCount,
            total: result.totalQuestions,
            xpEarned: result.xpEarned,
            sentenceResults: result.sentenceResults
        )))
    }

    // ── Swipe ──────────────────────────────────────────────────────────────

    private var swipeGesture: some Gesture {
        // neden minimumDistance 24: kelime chip'lerine tıklama ile çakışmasın
        DragGesture(minimumDistance: 24)
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
                    withAnimation(.spring(duration: 0.42)) { dragOffset = 0 }
                }
            }
    }

    private var canGoForward: Bool {
        if history.isInHistory { return true }
        return viewModel?.question?.isChecked == true
    }

    private func goForward() {
        if history.isInHistory {
            history.goForwardInHistory()
        } else if viewModel?.question?.isChecked == true {
            viewModel?.nextQuestion()
        }
    }
}
