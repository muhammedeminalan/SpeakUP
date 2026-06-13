import SwiftUI

/// Cümle kurma sonuç ekranı
struct SentenceResultView: View {
    let payload: SentenceResultPayload

    @Environment(Router.self) private var router

    var body: some View {
        let correctResults = payload.sentenceResults.filter(\.isCorrect)
        let wrongResults = payload.sentenceResults.filter { !$0.isCorrect }

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
                        if !payload.wrongSentenceIds.isEmpty {
                            Button("🔄 Yanlışları Tekrar Et", action: retryWrongs)
                                .buttonStyle(FilledAppButtonStyle())
                        }
                        Button("Ana Sayfaya Dön") { router.popToRoot() }
                            .buttonStyle(TonalAppButtonStyle())
                    }
                    .padding(.horizontal, AppConstants.paddingXL)

                    if !correctResults.isEmpty {
                        ResultSectionHeader(
                            label: "Doğru Cevaplananlar",
                            count: correctResults.count,
                            color: AppTheme.correct
                        )
                        ForEach(correctResults, id: \.self) { result in
                            CorrectSentenceResultCard(result: result)
                                .padding(.horizontal, AppConstants.paddingXL)
                        }
                    }

                    if !wrongResults.isEmpty {
                        ResultSectionHeader(
                            label: "Yanlış Cevaplananlar",
                            count: wrongResults.count,
                            color: AppTheme.wrong
                        )
                        ForEach(wrongResults, id: \.self) { result in
                            WrongSentenceResultCard(result: result)
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

    // Yanlışlar öncelikli, sonra denenmemişler, sonra öğrenilenler
    private func retryWrongs() {
        let retrySentences = buildRetrySentences()
        router.replace(with: .sentenceBuilder(SentenceBuilderPayload(
            chapterId: payload.chapterId,
            sentences: retrySentences,
            questionCount: retrySentences.count
        )))
    }

    private func resolveRetryCount() -> Int {
        if payload.defaultQuestionCount <= 0 {
            return payload.allSentences.count <= 10 ? payload.allSentences.count : 10
        }
        return min(payload.defaultQuestionCount, payload.allSentences.count)
    }

    private func buildRetrySentences() -> [Sentence] {
        let targetCount = resolveRetryCount()
        let wrongSet = Set(payload.wrongSentenceIds)
        let attemptedSet = Set(payload.attemptedSentenceIds)

        let prioritized = payload.allSentences.filter { wrongSet.contains($0.id) }
        let unknown = payload.allSentences.filter {
            !attemptedSet.contains($0.id) && !wrongSet.contains($0.id)
        }
        let learned = payload.allSentences.filter {
            attemptedSet.contains($0.id) && !wrongSet.contains($0.id)
        }

        return Array((prioritized + unknown + learned).prefix(targetCount))
    }
}

// ── Sonuç kartları ───────────────────────────────────────────────────────────

struct CorrectSentenceResultCard: View {
    let result: SentenceResult

    var body: some View {
        ResultCardContainer(accentColor: AppTheme.correct) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.sentence.turkish)
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                HStack {
                    Text(result.sentence.english)
                        .appFont(AppConstants.fontL, weight: .semibold)
                        .foregroundStyle(AppTheme.onSurface)
                    Spacer()
                    SpeakButton(text: result.sentence.english, size: 20)
                }
            }
        }
    }
}

struct WrongSentenceResultCard: View {
    let result: SentenceResult

    var body: some View {
        ResultCardContainer(accentColor: AppTheme.wrong) {
            VStack(alignment: .leading, spacing: AppConstants.paddingS) {
                Text(result.sentence.turkish)
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                Text("✗ Senin cevabın: \(result.userAnswer.isEmpty ? "(boş)" : result.userAnswer)")
                    .appFont(AppConstants.fontS)
                    .foregroundStyle(AppTheme.wrong)
                HStack {
                    Text("✓ Doğrusu: \(result.sentence.english)")
                        .appFont(AppConstants.fontS)
                        .foregroundStyle(AppTheme.correct)
                    Spacer()
                    SpeakButton(text: result.sentence.english, size: 18)
                }
            }
        }
    }
}
