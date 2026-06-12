import SwiftUI

/// Ayarlar sayfası — görünüm, metin boyutu, sesli okuma, oyun ve hakkında bölümleri
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: 0) {
            GradientNavBar(title: "Ayarlar")

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: AppConstants.paddingM)

                    sectionHeader("GÖRÜNÜM")
                    themeSection
                    sectionGap()

                    sectionHeader("METİN BOYUTU")
                    fontSizeSection
                    sectionGap()

                    sectionHeader("SESLİ OKUMA")
                    speechSection
                    sectionGap()

                    sectionHeader("OYUN")
                    gameSection
                    sectionGap()

                    sectionHeader("HAKKINDA")
                    aboutSection
                    sectionGap()
                }
            }
        }
        .background(AppTheme.surface)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // ── Görünüm ────────────────────────────────────────────────────────────

    private var themeSection: some View {
        sectionCard {
            VStack(spacing: 0) {
                selectionTile(
                    icon: "circle.lefthalf.filled",
                    label: "Sisteme Göre",
                    subtitle: "Cihazın temasını takip eder",
                    isSelected: settings.themeMode == .system
                ) { settings.themeMode = .system }
                tileDivider()
                selectionTile(
                    icon: "sun.max.fill",
                    label: "Açık Tema",
                    subtitle: "Her zaman açık tema",
                    isSelected: settings.themeMode == .light
                ) { settings.themeMode = .light }
                tileDivider()
                selectionTile(
                    icon: "moon.fill",
                    label: "Koyu Tema",
                    subtitle: "Her zaman koyu tema",
                    isSelected: settings.themeMode == .dark
                ) { settings.themeMode = .dark }
            }
        }
    }

    // ── Metin boyutu ───────────────────────────────────────────────────────

    private var fontSizeSection: some View {
        @Bindable var settings = settings

        return sectionCard {
            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    // neden fixedAppFont: örnek metin global ölçekten etkilenmesin
                    Text("Aa")
                        .fixedAppFont(CGFloat(settings.fontSize), weight: .bold)
                        .foregroundStyle(AppTheme.primary)
                    Spacer()
                    Text("\(settings.fontSize) pt")
                        .appFont(AppConstants.fontS, weight: .semibold)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings.fontSize) },
                        set: { settings.fontSize = Int($0.rounded()) }
                    ),
                    in: Double(AppSettings.minFontSize)...Double(AppSettings.maxFontSize),
                    step: Double(AppSettings.fontStep)
                )
                .tint(AppTheme.primary)
                HStack {
                    Text("\(AppSettings.minFontSize) pt")
                    Spacer()
                    Text("Varsayılan: \(AppSettings.defaultFontSize) pt")
                    Spacer()
                    Text("\(AppSettings.maxFontSize) pt")
                }
                .appFont(AppConstants.fontXS)
                .foregroundStyle(AppTheme.onSurfaceVariant)
            }
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, AppConstants.paddingM)
        }
    }

    // ── Sesli okuma ────────────────────────────────────────────────────────

    private var speechSection: some View {
        @Bindable var settings = settings

        return VStack(spacing: AppConstants.paddingM) {
            sectionCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Okuma Hızı")
                            .appFont(AppConstants.fontL, weight: .semibold)
                            .foregroundStyle(AppTheme.onSurface)
                        Spacer()
                        Text(settings.speechRate.speechRateLabel)
                            .appFont(AppConstants.fontS, weight: .bold)
                            .foregroundStyle(AppTheme.primary)
                    }
                    Slider(value: $settings.speechRate, in: AppSettings.minRate...AppSettings.maxRate)
                        .tint(AppTheme.primary)
                    HStack {
                        Text("Yavaş")
                        Spacer()
                        Text("Hızlı")
                    }
                    .appFont(AppConstants.fontXS)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                .padding(.horizontal, AppConstants.paddingL)
                .padding(.vertical, AppConstants.paddingM)
            }

            sectionCard {
                VStack(spacing: 0) {
                    ForEach(Array(TTSAccent.allCases.enumerated()), id: \.element) { index, accent in
                        if index != 0 { tileDivider() }
                        selectionTile(
                            icon: accent == .british ? "globe" : "person.wave.2.fill",
                            label: "\(accent.flag)  \(accent.label) Aksanı",
                            subtitle: accent.detail,
                            isSelected: settings.accent == accent
                        ) { settings.accent = accent }
                    }
                }
            }
        }
    }

    // ── Oyun ───────────────────────────────────────────────────────────────

    private var gameSection: some View {
        @Bindable var settings = settings

        return sectionCard {
            HStack(spacing: AppConstants.paddingM) {
                iconBox(
                    icon: "forward.end.fill",
                    isActive: settings.autoAdvance
                )
                VStack(alignment: .leading, spacing: 1) {
                    Text("Otomatik Geçiş")
                        .appFont(AppConstants.fontL, weight: .semibold)
                        .foregroundStyle(AppTheme.onSurface)
                    Text("Cevap sonrası soru otomatik ilerler")
                        .appFont(AppConstants.fontS)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                Spacer()
                Toggle("", isOn: $settings.autoAdvance)
                    .labelsHidden()
                    .tint(AppTheme.primary)
            }
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, 14)
        }
    }

    // ── Hakkında ───────────────────────────────────────────────────────────

    private var aboutSection: some View {
        sectionCard {
            HStack(spacing: AppConstants.paddingM) {
                AppIconImage(size: 44, cornerRadius: AppConstants.radiusS + 2)
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppConstants.appDisplayName)
                        .appFont(AppConstants.fontL, weight: .bold)
                        .foregroundStyle(AppTheme.onSurface)
                    Text(appVersionText)
                        .appFont(AppConstants.fontM)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                Spacer()
            }
            .padding(AppConstants.paddingL)
        }
    }

    // neden Bundle: versiyon/build bilgisi hardcode kalmasın
    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version)+\(build)"
    }

    // ── Ortak bileşenler ───────────────────────────────────────────────────

    private func sectionHeader(_ label: String) -> some View {
        Text(label)
            .appFont(AppConstants.fontS, weight: .bold)
            .kerning(1.2)
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, AppConstants.paddingS)
    }

    private func sectionGap() -> some View {
        Spacer().frame(height: AppConstants.paddingXXL)
    }

    private func sectionCard(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background(AppTheme.surfaceContainer, in: RoundedRectangle(cornerRadius: AppConstants.radiusL))
            .padding(.horizontal, AppConstants.paddingL)
    }

    private func tileDivider() -> some View {
        Divider()
            .overlay(AppTheme.outlineVariant)
            .padding(.leading, 56)
    }

    private func iconBox(icon: String, isActive: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundStyle(isActive ? AppTheme.primary : AppTheme.onSurfaceVariant)
            .frame(width: 36, height: 36)
            .background(
                isActive ? AppTheme.primary.opacity(0.2) : AppTheme.onSurface.opacity(0.08),
                in: RoundedRectangle(cornerRadius: AppConstants.radiusS)
            )
    }

    private func selectionTile(
        icon: String,
        label: String,
        subtitle: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: AppConstants.paddingM) {
                iconBox(icon: icon, isActive: isSelected)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .appFont(AppConstants.fontL, weight: .semibold)
                        .foregroundStyle(AppTheme.onSurface)
                    Text(subtitle)
                        .appFont(AppConstants.fontS)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant)
            }
            .padding(.horizontal, AppConstants.paddingL)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
