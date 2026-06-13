import SwiftUI

/// Quiz içi ayar sheet'i — font boyutu + okuma hızı + aksan + ses + otomatik
/// geçiş + ara ver. Flutter'daki quiz_options_sheet karşılığı.
struct QuizOptionsSheet: View {
    /// "Ara Ver": oturumu kaydedip quiz'den çıkar
    let onPause: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Oyun Ayarları")
                    .appFont(AppConstants.fontL, weight: .bold)
                    .foregroundStyle(AppTheme.onSurface)
                sectionGap()

                // ── Metin boyutu ───────────────────────────────────────
                sectionLabel("Metin Boyutu")
                HStack(spacing: AppConstants.paddingS) {
                    sizeButton(icon: "textformat.size.smaller", enabled: settings.fontSize > AppSettings.minFontSize) {
                        settings.decreaseFontSize()
                    }
                    VStack(spacing: 2) {
                        Slider(
                            value: fontSizeBinding,
                            in: Double(AppSettings.minFontSize)...Double(AppSettings.maxFontSize),
                            step: Double(AppSettings.fontStep)
                        )
                        Text("\(settings.fontSize) pt")
                            .fixedAppFont(AppConstants.fontS, weight: .bold)
                            .foregroundStyle(AppTheme.primary)
                    }
                    sizeButton(icon: "textformat.size.larger", enabled: settings.fontSize < AppSettings.maxFontSize) {
                        settings.increaseFontSize()
                    }
                }
                divider()

                // ── Sesli okuma hızı ───────────────────────────────────
                sectionLabel("Sesli Okuma Hızı")
                Slider(value: $settings.speechRate, in: AppSettings.minRate...AppSettings.maxRate)
                HStack {
                    Text("Yavaş").appFont(AppConstants.fontXS).foregroundStyle(AppTheme.onSurfaceVariant)
                    Spacer()
                    Text(settings.speechRate.speechRateLabel)
                        .appFont(AppConstants.fontXS, weight: .bold)
                        .foregroundStyle(AppTheme.primary)
                    Spacer()
                    Text("Hızlı").appFont(AppConstants.fontXS).foregroundStyle(AppTheme.onSurfaceVariant)
                }
                divider()

                // ── Aksan ──────────────────────────────────────────────
                sectionLabel("Aksan")
                HStack(spacing: AppConstants.paddingS) {
                    ForEach(TTSAccent.allCases, id: \.self) { accent in
                        accentButton(accent)
                    }
                }
                divider()

                // ── Ses ────────────────────────────────────────────────
                settingToggle(
                    icon: settings.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    isActive: !settings.isMuted,
                    title: "Ses",
                    subtitle: "Sesli okuma ve geri bildirimleri aç/kapat",
                    isOn: Binding(get: { !settings.isMuted }, set: { settings.isMuted = !$0 })
                )
                divider()

                // ── Otomatik geçiş ─────────────────────────────────────
                settingToggle(
                    icon: "forward.end.fill",
                    isActive: settings.autoAdvance,
                    title: "Otomatik Geçiş",
                    subtitle: "Cevap sonrası soru otomatik ilerler",
                    isOn: $settings.autoAdvance
                )
                divider()

                // ── Ara Ver ────────────────────────────────────────────
                Button {
                    dismiss()
                    onPause()
                } label: {
                    Label("Ara Ver", systemImage: "pause.circle")
                        .appFont(AppConstants.fontL, weight: .semibold)
                        .foregroundStyle(AppTheme.primary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.radiusM)
                                .stroke(AppTheme.outline, lineWidth: 1)
                        )
                }
            }
            .padding(AppConstants.paddingXL)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.surfaceContainer)
    }

    // neden Binding köprüsü: Slider Double ister, ayar Int tutar
    private var fontSizeBinding: Binding<Double> {
        Binding(
            get: { Double(settings.fontSize) },
            set: { settings.fontSize = Int($0.rounded()) }
        )
    }

    // ── Alt bileşenler ─────────────────────────────────────────────────────

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .appFont(AppConstants.fontS, weight: .semibold)
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .padding(.bottom, AppConstants.paddingS)
    }

    private func sectionGap() -> some View {
        Spacer().frame(height: AppConstants.paddingL)
    }

    private func divider() -> some View {
        Divider()
            .overlay(AppTheme.outlineVariant)
            .padding(.vertical, AppConstants.paddingM)
    }

    private func sizeButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(enabled ? AppTheme.onSurface : AppTheme.onSurfaceVariant)
                .frame(width: 40, height: 40)
                .background(
                    AppTheme.surfaceContainerHigh.opacity(enabled ? 1 : 0.4),
                    in: RoundedRectangle(cornerRadius: AppConstants.radiusM)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.radiusM)
                        .stroke(AppTheme.outlineVariant, lineWidth: 1)
                )
        }
        .disabled(!enabled)
    }

    private func accentButton(_ accent: TTSAccent) -> some View {
        let isSelected = settings.accent == accent
        return Button {
            settings.accent = accent
        } label: {
            VStack(spacing: 4) {
                Text(accent.flag).font(.system(size: 22))
                Text(accent.label)
                    .appFont(AppConstants.fontS, weight: isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? AppTheme.primary.opacity(0.15) : AppTheme.surfaceContainerHigh,
                in: RoundedRectangle(cornerRadius: AppConstants.radiusM)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.radiusM)
                    .stroke(isSelected ? AppTheme.primary : AppTheme.outlineVariant, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }

    private func settingToggle(
        icon: String,
        isActive: Bool,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: AppConstants.paddingM) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isActive ? AppTheme.primary : AppTheme.onSurfaceVariant)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appFont(AppConstants.fontM, weight: .semibold)
                    .foregroundStyle(AppTheme.onSurface)
                Text(subtitle)
                    .appFont(AppConstants.fontXS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.primary)
        }
    }
}
