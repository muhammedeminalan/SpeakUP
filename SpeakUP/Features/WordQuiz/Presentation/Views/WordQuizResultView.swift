import SwiftUI

/// Kelime quizi sonuç ekranı — skor + tekrar et + doğru/yanlış listeleri
struct WordQuizResultView: View {
    let payload: WordQuizResultPayload

    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps

    var body: some View {
        VStack(spacing: 0) {
            GradientNavBar(title: "Sonuçlar", onBack: { router.popToRoot() })

            ScrollView {
                VStack(spacing: 0) {
                    QuizResultScoreSection(
                        correct: payload.correct,
                        total: payload.total,
                        xpEarned: payload.xpEarned
                    )

                    VStack(spacing: AppConstants.paddingS) {
                        if !payload.wrongWordIds.isEmpty {
                            Button("🔄 Yanlışları Tekrar Et", action: retryWrongs)
                                .buttonStyle(FilledAppButtonStyle())
                        }
                        Button("Ana Sayfaya Dön") { router.popToRoot() }
                            .buttonStyle(TonalAppButtonStyle())
                    }
                    .padding(.horizontal, AppConstants.paddingXL)

                    if !payload.correctWords.isEmpty {
                        ResultSectionHeader(
                            label: "Doğru Cevaplananlar",
                            count: payload.correctWords.count,
                            color: AppTheme.correct
                        )
                        ForEach(payload.correctWords) { word in
                            CorrectWordResultCard(word: word)
                                .padding(.horizontal, AppConstants.paddingXL)
                        }
                    }

                    if !payload.wrongAnswerDetails.isEmpty {
                        ResultSectionHeader(
                            label: "Yanlış Cevaplananlar",
                            count: payload.wrongAnswerDetails.count,
                            color: AppTheme.wrong
                        )
                        ForEach(payload.wrongAnswerDetails, id: \.self) { detail in
                            WrongWordResultCard(detail: detail)
                                .padding(.horizontal, AppConstants.paddingXL)
                        }
                    }

                    Spacer().frame(height: AppConstants.paddingXXL)
                }
            }
        }
        .background(AppTheme.surface)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // Soru sayısı tercihi korunarak yanlış ağırlıklı yeni quiz başlatılır
    private func retryWrongs() {
        let targetCount = resolveRetryCount()
        let retryWords = deps.retryWordSetBuilder.build(
            chapterWords: payload.chapterWords,
            prioritizedWordIds: Set(payload.wrongWordIds),
            attemptedWordIds: Set(payload.attemptedWordIds),
            targetCount: targetCount
        )
        router.replace(with: .wordQuiz(WordQuizPayload(
            chapterId: payload.chapterId,
            words: retryWords,
            settings: QuizSettings(questionCount: retryWords.count, direction: payload.direction)
        )))
    }

    private func resolveRetryCount() -> Int {
        if payload.defaultQuestionCount <= 0 {
            return payload.chapterWords.count <= 10 ? payload.chapterWords.count : 10
        }
        return min(payload.defaultQuestionCount, payload.chapterWords.count)
    }
}

// ── Sonuç kartları ───────────────────────────────────────────────────────────

struct CorrectWordResultCard: View {
    let word: Word

    var body: some View {
        ResultCardContainer(accentColor: AppTheme.correct) {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.english)
                    .appFont(AppConstants.fontL, weight: .semibold)
                    .foregroundStyle(AppTheme.onSurface)
                Text(word.turkish)
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
        }
    }
}

struct WrongWordResultCard: View {
    let detail: WrongAnswerDetail

    var body: some View {
        ResultCardContainer(accentColor: AppTheme.wrong) {
            VStack(alignment: .leading, spacing: 2) {
                Text(detail.word.english)
                    .appFont(AppConstants.fontL, weight: .semibold)
                    .foregroundStyle(AppTheme.onSurface)
                Text(detail.word.turkish)
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                Spacer().frame(height: AppConstants.paddingS)
                Text("✗ Seçilen: \(detail.selectedAnswer)")
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.wrong)
                Text("✓ Doğrusu: \(detail.correctAnswer)")
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.correct)
            }
        }
    }
}
