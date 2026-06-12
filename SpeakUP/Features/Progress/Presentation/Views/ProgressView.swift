import SwiftUI

/// Bölüm ilerleme ekranı — Kelime / Cümle sekmeleri
struct ChapterProgressView: View {
    let payload: ProgressPayload

    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps

    @State private var viewModel: ProgressViewModel?
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            GradientNavBar(title: "İlerleme")

            // Sekme çubuğu — Flutter'daki TabBar'ın gradient bar altındaki karşılığı
            tabBar

            content
        }
        .background(AppTheme.surface)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: setupIfNeeded)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "Kelime", index: 0)
            tabButton(title: "Cümle", index: 1)
        }
        .background(AppColors.appBarGradient)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .appFont(AppConstants.fontM, weight: .semibold)
                    .foregroundStyle(selectedTab == index ? .white : .white.opacity(0.7))
                Rectangle()
                    .fill(selectedTab == index ? .white : .clear)
                    .frame(height: 2)
            }
            .padding(.top, AppConstants.paddingS)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            switch viewModel.state {
            case .loading:
                SwiftUI.ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .error(message):
                AppErrorState(
                    title: "İlerleme Yüklenemedi",
                    message: message,
                    onRetry: { viewModel.load(chapterId: payload.chapterId, words: payload.words, sentences: payload.sentences) },
                    onGoHome: { router.popToRoot() }
                )
            case .data:
                TabView(selection: $selectedTab) {
                    wordTab(viewModel).tag(0)
                    sentenceTab(viewModel).tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        } else {
            SwiftUI.ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func wordTab(_ viewModel: ProgressViewModel) -> some View {
        ProgressTabContent(
            emptyIcon: "chart.bar.fill",
            emptyTitle: "Henüz Quiz Yok",
            emptyMessage: "Kelime quizini tamamladıkça ilerlemen burada görünür.",
            isEmpty: viewModel.attemptedWords.isEmpty,
            learned: viewModel.learnedWords.count,
            retry: viewModel.retryWords.count,
            total: viewModel.words.count,
            notStarted: viewModel.notStartedCount,
            completionRatio: viewModel.completionRatio,
            retryEntries: viewModel.retryWords.map { ProgressEntry(turkish: $0.turkish, english: $0.english) },
            learnedEntries: viewModel.learnedWords.map { ProgressEntry(turkish: $0.turkish, english: $0.english) }
        ) {
            wordActionBar(viewModel)
        }
    }

    private func sentenceTab(_ viewModel: ProgressViewModel) -> some View {
        ProgressTabContent(
            emptyIcon: "puzzlepiece.extension.fill",
            emptyTitle: "Henüz Cümle Yok",
            emptyMessage: "Cümle kurmayı tamamladıkça ilerlemen burada görünür.",
            isEmpty: viewModel.attemptedSentences.isEmpty,
            learned: viewModel.learnedSentences.count,
            retry: viewModel.retrySentences.count,
            total: viewModel.sentences.count,
            notStarted: viewModel.notStartedSentenceCount,
            completionRatio: viewModel.sentenceCompletionRatio,
            retryEntries: viewModel.retrySentences.map { ProgressEntry(turkish: $0.turkish, english: $0.english) },
            learnedEntries: viewModel.learnedSentences.map { ProgressEntry(turkish: $0.turkish, english: $0.english) }
        ) {
            sentenceActionBar(viewModel)
        }
    }

    // ── Aksiyon barları ────────────────────────────────────────────────────

    private func wordActionBar(_ viewModel: ProgressViewModel) -> some View {
        VStack(spacing: AppConstants.paddingS) {
            Button("Tekrar Et (Yanlışlar)") {
                router.navigate(to: .wordQuiz(WordQuizPayload(
                    chapterId: viewModel.chapterId,
                    words: viewModel.retryWords,
                    settings: QuizSettings(questionCount: viewModel.retryWords.count),
                    // neden optionPool: 4 şık üretmek için tüm bölüm kelimeleri gerekli
                    optionPool: viewModel.words
                )))
            }
            .buttonStyle(FilledAppButtonStyle(height: 48))
            .disabled(viewModel.retryWords.isEmpty)
            .opacity(viewModel.retryWords.isEmpty ? 0.5 : 1)

            Button("Bölümü Çöz (Tümü)") {
                router.navigate(to: .wordQuiz(WordQuizPayload(
                    chapterId: viewModel.chapterId,
                    words: viewModel.words,
                    settings: QuizSettings(questionCount: viewModel.words.count),
                    optionPool: viewModel.words
                )))
            }
            .buttonStyle(TonalAppButtonStyle(height: 48))
            .disabled(viewModel.words.isEmpty)
        }
        .padding(.horizontal, AppConstants.paddingL)
        .padding(.bottom, AppConstants.paddingS)
    }

    private func sentenceActionBar(_ viewModel: ProgressViewModel) -> some View {
        Button("Tekrar Et (Yanlışlar)") {
            router.navigate(to: .sentenceBuilder(SentenceBuilderPayload(
                chapterId: viewModel.chapterId,
                sentences: viewModel.retrySentences,
                questionCount: viewModel.retrySentences.count
            )))
        }
        .buttonStyle(FilledAppButtonStyle(height: 48))
        .disabled(viewModel.retrySentences.isEmpty)
        .opacity(viewModel.retrySentences.isEmpty ? 0.5 : 1)
        .padding(.horizontal, AppConstants.paddingL)
        .padding(.bottom, AppConstants.paddingS)
    }

    private func setupIfNeeded() {
        guard viewModel == nil else { return }
        let vm = ProgressViewModel(
            wordRepository: deps.wordProgressRepository,
            sentenceRepository: deps.sentenceProgressRepository
        )
        vm.load(chapterId: payload.chapterId, words: payload.words, sentences: payload.sentences)
        viewModel = vm
    }
}
