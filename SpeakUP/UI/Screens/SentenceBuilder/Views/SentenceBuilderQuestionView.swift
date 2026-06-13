import SwiftUI

/// Tek bir cümle sorusunun görünümü — prompt kartı + drop alanı + kelime chip'leri
struct SentenceBuilderQuestionView: View {
    let state: SentenceQuestionState
    // neden: geçmiş cümleler read-only modda gösterilir
    let isReadOnly: Bool
    let onDrop: (String) -> Void
    let onRemove: (String) -> Void
    let onCheck: () -> Void
    let onNext: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(TTSService.self) private var tts

    var body: some View {
        VStack(spacing: 0) {
            QuizQuestionHeader(
                questionIndex: state.questionIndex,
                totalQuestions: state.totalQuestions,
                correctCount: state.correctCount,
                wrongCount: state.wrongCount,
                isReadOnly: isReadOnly,
                itemLabel: "cümle"
            )
            Spacer().frame(height: AppConstants.paddingM)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RevealableCard(
                        // neden: yöne göre prompt ve reveal metni yer değiştirir
                        prompt: state.promptText,
                        reveal: state.answerText,
                        isEnPrompt: state.direction == .enToTr,
                        // neden: kontrol sonrası cevap zaten geri bildirimde görünür
                        enabled: !state.isChecked
                    )
                    Spacer().frame(height: AppConstants.paddingS)

                    // neden: devrik sadece Türkçe → İngilizce yönünde anlamlı
                    if state.direction == .trToEn {
                        DevrikToggle(turkish: state.sentence.turkish)
                    }
                    Spacer().frame(height: AppConstants.paddingM)

                    if state.isChecked {
                        InlineFeedback(
                            isCorrect: state.isCorrect ?? false,
                            correctAnswer: state.answerText,
                            wasEmpty: state.placedWords.isEmpty,
                            // neden: EN→TR yönünde doğru cevap Türkçe, Türkçe ses gerekli
                            speakLocale: state.direction == .enToTr ? "tr-TR" : nil
                        )
                        if let warning = state.warningMessage {
                            Text(warning)
                                .appFont(AppConstants.fontXS)
                                .foregroundStyle(AppTheme.onSurfaceVariant)
                                .padding(.top, AppConstants.paddingS)
                        }
                        Spacer().frame(height: AppConstants.paddingM)
                    }

                    SentenceDropZone(
                        placedWords: state.placedWords,
                        isChecked: state.isChecked,
                        isCorrect: state.isCorrect,
                        onWordTapped: { word in
                            // neden her zaman TTS: cevap sonrasında da kelime dinlenebilir
                            if !settings.isMuted { tts.speakWord(word) }
                            // neden koşullu: sadece kontrol edilmemişse kelimeyi geri al
                            if !state.isChecked, !isReadOnly { onRemove(word) }
                        }
                    )
                    Spacer().frame(height: AppConstants.paddingM)

                    Divider().overlay(AppTheme.outlineVariant)
                    Spacer().frame(height: AppConstants.paddingS)

                    // Kelime havuzu — tıklayınca yerleştirilir
                    WrapLayout(spacing: AppConstants.paddingS) {
                        ForEach(state.availableWords, id: \.self) { word in
                            WordChip(word: word, isEnabled: !state.isChecked) {
                                if !settings.isMuted { tts.speakWord(word) }
                                if !state.isChecked, !isReadOnly { onDrop(word) }
                            }
                        }
                    }
                    Spacer().frame(height: AppConstants.paddingM)
                }
                .padding(.horizontal, AppConstants.paddingXL)
            }

            bottomButton
        }
        .onChange(of: state.isChecked) { wasChecked, isChecked in
            // neden: cümle modunda auto-advance yok — kullanıcı kontrolünde;
            // doğru cevap verilince cümle otomatik seslendirilir
            guard isChecked, !wasChecked, state.isCorrect == true, !isReadOnly else { return }
            autoSpeak()
        }
    }

    private var bottomButton: some View {
        Button {
            if state.isChecked {
                onNext()
            } else {
                // neden: "Geç" = mevcut dizilimi gönderir; boşsa yanlış sayılır
                onCheck()
            }
        } label: {
            Text(buttonLabel)
        }
        .buttonStyle(FilledAppButtonStyle(background: buttonColor, height: 46))
        .disabled(isReadOnly)
        .padding(.horizontal, AppConstants.paddingXL)
        .padding(.top, AppConstants.paddingS)
        .padding(.bottom, AppConstants.paddingXL)
    }

    private var buttonLabel: String {
        guard state.isChecked else { return "Geç" }
        return state.remainingQuestions == 0 ? "Bitir" : "Sonraki Cümle"
    }

    private var buttonColor: Color {
        guard state.isChecked else { return AppTheme.primary }
        return (state.isCorrect ?? false) ? AppTheme.correct : AppTheme.wrong
    }

    private func autoSpeak() {
        guard !settings.isMuted else { return }
        // neden direction kontrolü: enToTr'de cevap Türkçe — tr-TR locale ile okunmalı
        if state.direction == .enToTr {
            tts.speak(state.answerText, withLocale: "tr-TR")
        } else {
            tts.speak(state.answerText)
        }
    }
}

// ── Geri bildirim kutusu ─────────────────────────────────────────────────────

private struct InlineFeedback: View {
    let isCorrect: Bool
    let correctAnswer: String
    // neden: boş geçilen sorularda "Yanlış" yerine "Boş bırakıldı" gösterilir
    var wasEmpty = false
    var speakLocale: String? = nil

    private var color: Color { isCorrect ? AppTheme.correct : AppTheme.wrong }

    private var label: String {
        if isCorrect { return "✅ Harika! Doğru!" }
        return wasEmpty ? "📭 Boş bırakıldı" : "❌ Yanlış"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .appFont(AppConstants.fontM, weight: .bold)
                .foregroundStyle(color)
            if !isCorrect {
                HStack {
                    Text("✔ \(correctAnswer)")
                        .appFont(AppConstants.fontM)
                        .foregroundStyle(AppTheme.correct)
                    Spacer()
                    SpeakButton(text: correctAnswer, size: 20, locale: speakLocale)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppConstants.paddingM)
        .padding(.vertical, AppConstants.paddingS + 2)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: AppConstants.radiusM))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusM)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
    }
}

// ── Devrik cümle paneli ──────────────────────────────────────────────────────

private struct DevrikToggle: View {
    let turkish: String

    @State private var isOpen = false

    // Kelimeler ters çevrilerek devrik yapı üretilir
    private var devrik: String {
        turkish.trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .reversed()
            .joined(separator: " ")
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) { isOpen.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                    Text("Devrik cümle")
                        .appFont(AppConstants.fontXS, weight: .semibold)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                if isOpen {
                    Spacer().frame(height: AppConstants.paddingS)
                    Text(devrik)
                        .appFont(AppConstants.fontL, weight: .medium)
                        .foregroundStyle(AppTheme.onSurface)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, AppConstants.paddingM)
            .background(
                isOpen ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainer,
                in: RoundedRectangle(cornerRadius: AppConstants.radiusL)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.radiusL)
                    .stroke(AppTheme.outlineVariant, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        // neden: yeni soru gelince devrik paneli kapanır
        .onChange(of: turkish) { _, _ in isOpen = false }
    }
}

// ── Prompt kartı: basılı tutunca cevabı gösterir ─────────────────────────────

private struct RevealableCard: View {
    let prompt: String
    let reveal: String
    // neden: EN→TR yönünde prompt İngilizce, bayrak 🇬🇧 gösterilmeli
    var isEnPrompt = false
    let enabled: Bool

    @State private var isRevealed = false

    private var show: Bool { isRevealed && enabled }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.paddingXS) {
            HStack {
                Text(show
                    ? (isEnPrompt ? "🇹🇷" : "🇬🇧")
                    : (isEnPrompt ? "🇬🇧" : "🇹🇷"))
                    .appFont(AppConstants.fontXS)
                if enabled {
                    Spacer()
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.onSurfaceVariant.opacity(0.5))
                }
            }
            Text(show ? reveal : prompt)
                .appFont(AppConstants.fontXXL, weight: .bold)
                .foregroundStyle(show ? AppTheme.correct : AppTheme.onSurface)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.15), value: show)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.paddingL)
        .background(
            show ? AppTheme.correct.opacity(0.08) : AppTheme.surfaceContainer,
            in: RoundedRectangle(cornerRadius: AppConstants.radiusL)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusL)
                .stroke(show ? AppTheme.correct.opacity(0.4) : AppTheme.outlineVariant, lineWidth: 1)
        )
        // neden basılı tut: anında yanıt — uzun basma gecikmesi olmadan göster/gizle
        .onLongPressGesture(minimumDuration: .infinity) {
        } onPressingChanged: { pressing in
            guard enabled else { return }
            isRevealed = pressing
        }
        // neden: soru değişince reveal sıfırlanır
        .onChange(of: prompt) { _, _ in isRevealed = false }
    }
}

// ── Drop alanı ───────────────────────────────────────────────────────────────

/// Yerleştirilen kelimeleri gösterir; üstüne tıklayınca kelime geri alınır
private struct SentenceDropZone: View {
    let placedWords: [String]
    let isChecked: Bool
    let isCorrect: Bool?
    let onWordTapped: (String) -> Void

    private var borderColor: Color {
        guard isChecked else { return AppTheme.outline }
        return (isCorrect ?? false) ? AppTheme.correct : AppTheme.wrong
    }

    private var chipColor: Color {
        guard isChecked else { return AppTheme.correct }
        return (isCorrect ?? false) ? AppTheme.correct : AppTheme.wrong
    }

    var body: some View {
        Group {
            if placedWords.isEmpty {
                Text("Kelimelere tıklayarak buraya ekle")
                    .appFont(AppConstants.fontM)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                    .frame(maxWidth: .infinity, minHeight: AppConstants.dropZoneMinHeight - AppConstants.paddingM * 2)
            } else {
                WrapLayout(spacing: AppConstants.paddingS) {
                    ForEach(placedWords, id: \.self) { word in
                        Button {
                            onWordTapped(word)
                        } label: {
                            Text(word)
                                .appFont(AppConstants.fontM, weight: .semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppConstants.paddingM)
                                .padding(.vertical, AppConstants.paddingS)
                                .background(chipColor, in: RoundedRectangle(cornerRadius: AppConstants.radiusL))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppConstants.paddingM)
        .frame(minHeight: AppConstants.dropZoneMinHeight)
        .background(AppTheme.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: AppConstants.radiusL))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusL)
                .stroke(borderColor, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isChecked)
    }
}

// ── Kelime chip'i ────────────────────────────────────────────────────────────

/// isEnabled=false (kontrol sonrası): tıklanınca sadece TTS — yerleştirme yok
private struct WordChip: View {
    let word: String
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(word)
                .appFont(AppConstants.fontL, weight: .semibold)
                .foregroundStyle(isEnabled ? .white : AppTheme.onSurfaceVariant)
                .padding(.horizontal, 14)
                .padding(.vertical, AppConstants.paddingS + 2)
                .background(
                    isEnabled ? AppTheme.primaryBlue : AppTheme.surfaceContainerHigh,
                    in: RoundedRectangle(cornerRadius: AppConstants.radiusXL)
                )
        }
        .buttonStyle(.plain)
    }
}
