import SwiftUI

/// Bölüm dashboard'u — başlık kartı + öğrenme modları + devam et bölümü
struct ChapterDashboardView: View {
    let chapter: Chapter

    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps
    @Environment(\.colorScheme) private var colorScheme

    @State private var activeSheet: SettingsSheetKind?

    // neden enum: kelime ve cümle ayar sheet'leri aynı item mekanizmasını paylaşır
    private enum SettingsSheetKind: Identifiable {
        case wordQuiz, sentenceBuilder
        var id: Int { self == .wordQuiz ? 0 : 1 }
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground(isDark: colorScheme == .dark)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerCard
                    Spacer().frame(height: AppConstants.paddingL)

                    Text("Öğrenme Modları")
                        .appFont(20, weight: .bold)
                        .foregroundStyle(AppTheme.onSurface)
                    Spacer().frame(height: AppConstants.paddingS)

                    resumeSection

                    ChapterModeCard(
                        order: 0,
                        icon: "questionmark.circle.fill",
                        title: "Kelime Quiz",
                        subtitle: "Hızlı testle kelime bilginizi ölç",
                        tag: "\(chapter.words.count) kelime",
                        gradientColors: AppColors.modeQuizGradient,
                        isDisabled: chapter.words.isEmpty
                    ) {
                        activeSheet = .wordQuiz
                    }
                    Spacer().frame(height: AppConstants.paddingM)

                    ChapterModeCard(
                        order: 1,
                        icon: "puzzlepiece.extension.fill",
                        title: "Cümle Kur",
                        subtitle: "Kelimeyi sürükle, doğru cümleyi tamamla",
                        tag: "\(chapter.sentences.count) cümle",
                        gradientColors: AppColors.modeSentenceGradient,
                        isDisabled: chapter.sentences.isEmpty
                    ) {
                        activeSheet = .sentenceBuilder
                    }
                    Spacer().frame(height: AppConstants.paddingM)

                    ChapterModeCard(
                        order: 2,
                        icon: "chart.bar.fill",
                        title: "İlerleme",
                        subtitle: "Öğrenilen ve zorlandığın alanları gör",
                        tag: "Detay analiz",
                        gradientColors: AppColors.modeProgressGradient,
                        isDisabled: chapter.words.isEmpty
                    ) {
                        router.navigate(to: .progress(ProgressPayload(
                            chapterId: chapter.id,
                            words: chapter.words,
                            sentences: chapter.sentences
                        )))
                    }

                    Spacer().frame(height: AppConstants.paddingL)
                    bottomHint
                }
                .padding(.horizontal, AppConstants.paddingL)
                .padding(.top, AppConstants.paddingM)
                .padding(.bottom, AppConstants.paddingXXL)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { kind in
            switch kind {
            case .wordQuiz:
                QuizSettingsSheet(title: "Kelime Quiz", availableCount: chapter.words.count) { count, direction in
                    router.navigate(to: .wordQuiz(WordQuizPayload(
                        chapterId: chapter.id,
                        words: chapter.words,
                        settings: QuizSettings(questionCount: count, direction: direction)
                    )))
                }
            case .sentenceBuilder:
                QuizSettingsSheet(title: "Cümle Kur", availableCount: chapter.sentences.count) { count, direction in
                    router.navigate(to: .sentenceBuilder(SentenceBuilderPayload(
                        chapterId: chapter.id,
                        sentences: chapter.sentences,
                        questionCount: count,
                        direction: direction
                    )))
                }
            }
        }
    }

    // ── Başlık kartı ───────────────────────────────────────────────────────

    private var headerCard: some View {
        VStack(spacing: AppConstants.paddingM) {
            HStack(spacing: AppConstants.paddingS) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "arrow.left")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2), in: Circle())
                }
                Text(chapter.name)
                    .appFont(19, weight: .bold)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack(spacing: AppConstants.paddingS) {
                HeroStatTile(icon: "textformat.abc", label: "Kelime", value: "\(chapter.words.count)")
                HeroStatTile(icon: "bubble.left", label: "Cümle", value: "\(chapter.sentences.count)")
                HeroStatTile(icon: "square.stack.3d.up.fill", label: "Toplam", value: "\(chapter.words.count + chapter.sentences.count)")
            }
        }
        .padding(AppConstants.paddingL)
        .background(AppColors.heroGradient, in: RoundedRectangle(cornerRadius: AppConstants.radiusXL))
    }

    // ── Devam Et bölümü ────────────────────────────────────────────────────

    @ViewBuilder
    private var resumeSection: some View {
        let wordSession = deps.sessionStore.wordSession(forChapter: chapter.id)
        let sentenceSession = deps.sessionStore.sentenceSession(forChapter: chapter.id)

        // neden erken kontrol: oturum yoksa bölüm hiç render edilmesin
        if wordSession != nil || sentenceSession != nil {
            VStack(spacing: AppConstants.paddingS) {
                if wordSession != nil {
                    Button {
                        router.navigate(to: .wordQuiz(WordQuizPayload(
                            chapterId: chapter.id,
                            words: chapter.words,
                            settings: wordSession?.settings ?? QuizSettings(questionCount: -1),
                            resume: true
                        )))
                    } label: {
                        Label("Kelime Quiz: Devam Et", systemImage: "play.fill")
                    }
                    .buttonStyle(FilledAppButtonStyle(height: 48))
                }
                if sentenceSession != nil {
                    Button {
                        router.navigate(to: .sentenceBuilder(SentenceBuilderPayload(
                            chapterId: chapter.id,
                            sentences: sentenceSession?.allSentences ?? chapter.sentences,
                            questionCount: sentenceSession?.questionCount ?? -1,
                            resume: true
                        )))
                    } label: {
                        Label("Cümle Kur: Devam Et", systemImage: "play.fill")
                    }
                    .buttonStyle(FilledAppButtonStyle(height: 48))
                }
            }
            .padding(.bottom, AppConstants.paddingM)
        }
    }

    private var bottomHint: some View {
        HStack(spacing: AppConstants.paddingS) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.primary)
            Text("\(chapter.name) için bir mod seçerek devam et.")
                .appFont(AppConstants.fontM, weight: .semibold)
                .foregroundStyle(AppTheme.onSurfaceVariant)
            Spacer()
        }
        .padding(AppConstants.paddingM)
        .background(AppTheme.surfaceContainer.opacity(0.62), in: RoundedRectangle(cornerRadius: AppConstants.radiusL))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusL)
                .stroke(AppTheme.outlineVariant.opacity(0.5), lineWidth: 1)
        )
    }
}

// ── Öğrenme modu kartı ───────────────────────────────────────────────────────

struct ChapterModeCard: View {
    var order = 0
    let icon: String
    let title: String
    let subtitle: String
    let tag: String
    let gradientColors: [Color]
    var isDisabled = false
    let onTap: () -> Void

    @State private var appeared = false

    private var accent: Color { gradientColors[0] }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.paddingL) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .shadow(color: accent.opacity(0.3), radius: 6, y: 5)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .appFont(17, weight: .bold)
                        .foregroundStyle(AppTheme.onSurface)
                    Text(subtitle)
                        .appFont(AppConstants.fontM)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                    Text(tag)
                        .appFont(12, weight: .bold)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.22) },
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .padding(.top, AppConstants.paddingXS)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(accent)
            }
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, AppConstants.paddingM + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceContainer)
            .overlay(alignment: .leading) {
                Rectangle().fill(accent).frame(width: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.radiusL))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(appeared ? (isDisabled ? 0.5 : 1) : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.easeOut(duration: Double(min(220 + order * 70, 900)) / 1000)) {
                appeared = true
            }
        }
    }
}
