import SwiftUI

/// Quiz başlatma ayarları sheet'i — yön + soru sayısı seçimi.
/// neden tek bileşen: kelime ve cümle ayar sheet'leri Flutter'da neredeyse
/// aynıydı; başlık parametreyle değişir, kod tekrarı önlenir.
struct QuizSettingsSheet: View {
    let title: String
    let availableCount: Int
    /// Başla'ya basılınca (soru sayısı, yön) ile çağrılır; -1 = tümü
    let onStart: (Int, QuizDirection) -> Void

    @Environment(\.dismiss) private var dismiss

    // -1 = tümü, varsayılan: 10 veya mevcut sayı (hangisi küçükse)
    @State private var selectedCount: Int
    @State private var direction: QuizDirection = .trToEn

    private static let countOptions = [5, 10, 20]

    init(title: String, availableCount: Int, onStart: @escaping (Int, QuizDirection) -> Void) {
        self.title = title
        self.availableCount = availableCount
        self.onStart = onStart
        _selectedCount = State(initialValue: availableCount >= 10 ? 10 : -1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .appFont(20, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            Spacer().frame(height: AppConstants.paddingXL)

            sectionLabel("YÖN")
            Spacer().frame(height: AppConstants.paddingS)
            HStack(spacing: AppConstants.paddingS) {
                directionChip(from: "🇹🇷", to: "🇬🇧", value: .trToEn)
                directionChip(from: "🇬🇧", to: "🇹🇷", value: .enToTr)
            }
            Spacer().frame(height: AppConstants.paddingL)

            sectionLabel("SORU SAYISI")
            Spacer().frame(height: AppConstants.paddingS)
            WrapLayout(spacing: AppConstants.paddingS) {
                // Mevcut sayıdan küçük seçenekleri göster + Tümü her zaman var
                ForEach(Self.countOptions.filter { $0 <= availableCount }, id: \.self) { count in
                    countChip(label: "\(count) Soru", value: count)
                }
                countChip(label: "Tümü (\(availableCount))", value: -1)
            }
            Spacer().frame(height: AppConstants.paddingXXL)

            Button("Başla") {
                dismiss()
                onStart(selectedCount, direction)
            }
            .buttonStyle(FilledAppButtonStyle(background: AppTheme.correct))
        }
        .padding(.horizontal, AppConstants.paddingXL)
        .padding(.top, AppConstants.paddingXL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.surfaceContainer)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .appFont(AppConstants.fontS, weight: .bold)
            .kerning(1.1)
            .foregroundStyle(AppTheme.onSurfaceVariant)
    }

    private func directionChip(from: String, to: String, value: QuizDirection) -> some View {
        let isSelected = direction == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { direction = value }
        } label: {
            HStack(spacing: 6) {
                Text(from).font(.system(size: 22))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : AppTheme.onSurfaceVariant)
                Text(to).font(.system(size: 22))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.paddingM)
            .background(
                isSelected ? AppTheme.primaryBlue : AppTheme.surfaceContainerHigh,
                in: RoundedRectangle(cornerRadius: AppConstants.radiusXL)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.radiusXL)
                    .stroke(isSelected ? AppTheme.primaryBlue : AppTheme.outlineVariant, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func countChip(label: String, value: Int) -> some View {
        let isSelected = selectedCount == value
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedCount = value }
        } label: {
            Text(label)
                .appFont(AppConstants.fontL, weight: .semibold)
                .foregroundStyle(isSelected ? .white : AppTheme.onSurface)
                .padding(.horizontal, AppConstants.paddingL)
                .padding(.vertical, AppConstants.paddingS + 2)
                .background(
                    isSelected ? AppTheme.primaryBlue : AppTheme.surfaceContainerHigh,
                    in: RoundedRectangle(cornerRadius: AppConstants.radiusXL)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.radiusXL)
                        .stroke(isSelected ? AppTheme.primaryBlue : AppTheme.outlineVariant, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
