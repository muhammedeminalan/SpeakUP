import SwiftUI

/// Tek bir sorunun görünümü — kart + şıklar + alt buton
struct WordQuizQuestionView: View {
    let state: WordQuizQuestionState
    // neden: geçmiş sorular read-only modda gösterilir — buton/event yok
    let isReadOnly: Bool
    let onSelect: (String) -> Void
    let onNext: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(TTSService.self) private var tts

    // neden token: eski sorunun zamanlayıcısı yeni soruyu ilerletmesin
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            QuizQuestionHeader(
                questionIndex: state.questionIndex,
                totalQuestions: state.totalQuestions,
                correctCount: state.correctCount,
                wrongCount: state.wrongCount,
                isReadOnly: isReadOnly
            )
            Spacer().frame(height: AppConstants.paddingM)

            ScrollView {
                VStack(spacing: 0) {
                    QuizWordCard(questionText: state.questionText, direction: state.direction)
                    Spacer().frame(height: AppConstants.paddingXL)

                    ForEach(Array(state.options.enumerated()), id: \.offset) { index, option in
                        AnswerOptionButton(
                            text: option,
                            index: index,
                            isAnswered: state.isAnswered,
                            isCorrectAnswer: option == state.correctAnswer,
                            isSelected: option == state.selectedAnswer,
                            // neden: enToTr'de seçenekler Türkçe — tr-TR locale ile okunmalı
                            speakLocale: state.direction == .enToTr ? "tr-TR" : nil,
                            // neden nil: read-only modda veya cevap verilmişse tıklama yok
                            onTap: (state.isAnswered || isReadOnly) ? nil : { onSelect(option) }
                        )
                        .padding(.bottom, AppConstants.paddingM)
                    }

                    if let warning = state.warningMessage {
                        Text(warning)
                            .appFont(AppConstants.fontM)
                            .foregroundStyle(AppTheme.wrong)
                            .padding(.top, AppConstants.paddingM)
                    }
                }
                .padding(.horizontal, AppConstants.paddingXL)
                .padding(.bottom, AppConstants.paddingM)
            }

            // neden: auto-advance açıkken buton hiç gösterilmez — sistem ilerler
            if !isReadOnly, !settings.autoAdvance {
                Button {
                    onNext()
                } label: {
                    Text(nextButtonLabel)
                }
                .buttonStyle(FilledAppButtonStyle(height: 46))
                .disabled(!state.isAnswered)
                .opacity(state.isAnswered ? 1 : 0.5)
                .padding(.horizontal, AppConstants.paddingXL)
                .padding(.top, AppConstants.paddingS)
                .padding(.bottom, AppConstants.paddingXL)
            }
        }
        .onChange(of: state.isAnswered) { wasAnswered, isAnswered in
            guard isAnswered, !wasAnswered else { return }
            autoSpeak()
            scheduleAutoAdvance()
        }
        .onDisappear { autoAdvanceTask?.cancel() }
    }

    private var nextButtonLabel: String {
        if state.remainingQuestions == 0 { return "Tamamla" }
        return state.isCorrect ? "Öğrendim" : "Devam Et"
    }

    private func autoSpeak() {
        guard !settings.isMuted else { return }
        // neden sadece doğruysa: yanlış cevaplar için kullanıcı kendi dinleyebilir
        guard state.isCorrect else { return }
        // neden direction kontrolü: enToTr'de doğru cevap Türkçe — tr-TR locale gerekli
        if state.direction == .enToTr {
            tts.speak(state.correctAnswer, withLocale: "tr-TR")
        } else {
            tts.speak(state.correctAnswer)
        }
    }

    private func scheduleAutoAdvance() {
        // neden: read-only modda (geçmiş soru) auto-advance çalışmasın
        guard !isReadOnly, settings.autoAdvance else { return }

        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task {
            // neden 2s: kullanıcıya cevabı görme süresi verilir
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            onNext()
        }
    }
}

// ── Soru kartı ───────────────────────────────────────────────────────────────

struct QuizWordCard: View {
    let questionText: String
    var direction: QuizDirection = .trToEn

    private var labelText: String {
        direction == .trToEn ? "🇹🇷 Türkçe" : "🇬🇧 İngilizce"
    }

    private var subtitleText: String {
        direction == .trToEn ? "İngilizce karşılığını seç" : "Türkçe karşılığını seç"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(labelText)
                .appFont(AppConstants.fontM)
                .foregroundStyle(.white.opacity(0.7))
            Spacer().frame(height: AppConstants.paddingM)
            Text(questionText.capitalizingSegments())
                .appFont(30, weight: .bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Spacer().frame(height: AppConstants.paddingS)
            Text(subtitleText)
                .appFont(AppConstants.fontM)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppColors.questionCardGradient, in: RoundedRectangle(cornerRadius: AppConstants.radiusChip))
        .shadow(color: AppTheme.primaryBlue.opacity(0.5), radius: 10, y: 8)
    }
}

// ── Cevap şıkkı butonu ───────────────────────────────────────────────────────

struct AnswerOptionButton: View {
    let text: String
    let index: Int
    let isAnswered: Bool
    let isCorrectAnswer: Bool
    let isSelected: Bool
    var speakLocale: String? = nil
    // neden nullable: cevap verilmişse dışarıdan nil geçilir
    let onTap: (() -> Void)?

    private static let labels = ["A", "B", "C", "D"]

    var body: some View {
        HStack(spacing: 0) {
            // ── Tıklanabilir alan: sadece label + metin kısmı ──────────────
            // neden ayrı buton: SpeakButton bu alanın dışında kalıyor —
            // ikisi aynı tıklama alanında olsaydı TTS ve şık seçimi
            // aynı anda tetiklenirdi
            Button {
                onTap?()
            } label: {
                HStack(spacing: AppConstants.paddingM) {
                    Text(label)
                        .appFont(AppConstants.fontM, weight: .bold)
                        .foregroundStyle(labelTextColor)
                        .frame(width: 32, height: 32)
                        .background(labelBackground, in: RoundedRectangle(cornerRadius: 8))

                    Text(text.capitalizingSegments())
                        .appFont(AppConstants.fontXL, weight: .semibold)
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, AppConstants.paddingM)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isAnswered || onTap == nil)

            // ── Sağ taraf: ses butonu her zaman sabit ──────────────────────
            // neden her zaman: kullanıcı cevaplamadan önce veya sonra dinleyebilsin
            SpeakButton(text: text, size: 18, locale: speakLocale)
                .padding(.trailing, AppConstants.paddingS)
        }
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: AppConstants.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusM)
                .stroke(borderColor, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.18), value: isAnswered)
    }

    private var label: String {
        index < Self.labels.count ? Self.labels[index] : "?"
    }

    // Cevap sonrası renkler: doğru şık yeşil, seçilen yanlış şık kırmızı
    private var backgroundColor: Color {
        guard isAnswered else { return AppTheme.surfaceContainer }
        if isCorrectAnswer { return AppTheme.correct.opacity(0.12) }
        if isSelected { return AppTheme.wrong.opacity(0.12) }
        return AppTheme.surfaceContainer
    }

    private var borderColor: Color {
        guard isAnswered else { return AppTheme.outline }
        if isCorrectAnswer { return AppTheme.correct }
        if isSelected { return AppTheme.wrong }
        return AppTheme.outline
    }

    private var textColor: Color {
        guard isAnswered else { return AppTheme.onSurface }
        if isCorrectAnswer { return AppTheme.correct }
        if isSelected { return AppTheme.wrong }
        return AppTheme.onSurface
    }

    private var labelBackground: Color {
        guard isAnswered else { return AppTheme.surfaceContainerHigh }
        if isCorrectAnswer { return AppTheme.correct }
        if isSelected { return AppTheme.wrong }
        return AppTheme.surfaceContainerHigh
    }

    private var labelTextColor: Color {
        guard isAnswered else { return AppTheme.onSurfaceVariant }
        if isCorrectAnswer || isSelected { return .white }
        return AppTheme.onSurfaceVariant
    }
}
