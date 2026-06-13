import SwiftUI

struct ProgressEntry: Hashable {
    let turkish: String
    let english: String
}

/// Sekme içeriği — istatistik kartı + aksiyonlar + tekrar/öğrenildi listeleri.
/// Kelime ve Cümle sekmeleri aynı bileşeni kullanır — kod tekrarı yok.
struct ProgressTabContent<Bottom: View>: View {
    let emptyIcon: String
    let emptyTitle: String
    let emptyMessage: String
    let isEmpty: Bool
    let learned: Int
    let retry: Int
    let total: Int
    let notStarted: Int
    let completionRatio: Double
    let retryEntries: [ProgressEntry]
    let learnedEntries: [ProgressEntry]
    @ViewBuilder var bottom: () -> Bottom

    var body: some View {
        if isEmpty {
            AppEmptyState(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ProgressStatsSection(
                        learned: learned,
                        retry: retry,
                        total: total,
                        notStarted: notStarted,
                        completionRatio: completionRatio
                    )

                    bottom()

                    VStack(alignment: .leading, spacing: 0) {
                        if !retryEntries.isEmpty {
                            sectionHeader(
                                label: "Tekrar Et",
                                count: retryEntries.count,
                                badgeColor: AppTheme.wrong,
                                icon: "arrow.clockwise"
                            )
                            ForEach(retryEntries, id: \.self) { entry in
                                WordStatusCard(turkish: entry.turkish, english: entry.english, isLearned: false)
                            }
                        }

                        if !learnedEntries.isEmpty {
                            sectionHeader(
                                label: "Öğrenildi",
                                count: learnedEntries.count,
                                badgeColor: AppTheme.correct,
                                icon: "checkmark.circle.fill"
                            )
                            ForEach(learnedEntries, id: \.self) { entry in
                                WordStatusCard(turkish: entry.turkish, english: entry.english, isLearned: true)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.paddingM)
                    .padding(.top, AppConstants.paddingS)
                    .padding(.bottom, AppConstants.paddingXL)
                }
            }
        }
    }

    private func sectionHeader(label: String, count: Int, badgeColor: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(badgeColor)
            Text(label)
                .appFont(AppConstants.fontL, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            Text("\(count)")
                .appFont(AppConstants.fontS, weight: .bold)
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(badgeColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Spacer()
        }
        .padding(.top, AppConstants.paddingM)
        .padding(.bottom, AppConstants.paddingXS)
    }
}

// ── İstatistik kartı: donut grafik + sayı chip'leri ──────────────────────────

struct ProgressStatsSection: View {
    let learned: Int
    let retry: Int
    let total: Int
    let notStarted: Int
    let completionRatio: Double

    var body: some View {
        VStack(spacing: AppConstants.paddingXL) {
            ZStack {
                DonutChart(learned: learned, retry: retry, total: total)
                    .frame(width: 160, height: 160)
                VStack(spacing: 2) {
                    Text("%\(Int((completionRatio * 100).rounded()))")
                        .appFont(32, weight: .black)
                        .foregroundStyle(AppTheme.onSurface)
                    Text("tamamlandı")
                        .appFont(AppConstants.fontXS)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }

            HStack(spacing: AppConstants.paddingM) {
                statChip(value: learned, label: "Öğrenildi", color: AppTheme.correct)
                statChip(value: retry, label: "Tekrar Et", color: AppTheme.wrong)
                statChip(value: notStarted, label: "Başlanmadı", color: AppTheme.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppConstants.paddingXL)
        .padding(.horizontal, AppConstants.paddingL)
        .background(AppTheme.surfaceContainer, in: RoundedRectangle(cornerRadius: AppConstants.radiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.radiusXL)
                .stroke(AppTheme.outlineVariant, lineWidth: 1)
        )
        .padding(AppConstants.paddingL)
    }

    private func statChip(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .appFont(AppConstants.fontXL, weight: .black)
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(color.opacity(0.12), in: Capsule())
            Text(label)
                .appFont(AppConstants.fontXS)
                .foregroundStyle(AppTheme.onSurfaceVariant)
        }
    }
}

/// Donut grafik — yeşil yay öğrenilenler (saat yönü), kırmızı yay tekrarlar (ters yön)
private struct DonutChart: View {
    let learned: Int
    let retry: Int
    let total: Int

    private static let strokeWidth: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: Self.strokeWidth)

            if total > 0 {
                if learned > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(learned) / CGFloat(total))
                        .stroke(
                            AppTheme.correct,
                            style: StrokeStyle(lineWidth: Self.strokeWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                if retry > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(retry) / CGFloat(total))
                        .stroke(
                            AppTheme.wrong.opacity(0.95),
                            style: StrokeStyle(lineWidth: Self.strokeWidth, lineCap: .round)
                        )
                        // neden ayna + döndürme: kırmızı yay tepe noktasından
                        // saat yönünün tersine çizilir — Flutter'daki negatif sweep
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(x: -1, y: 1)
                }
            }
        }
        .padding(Self.strokeWidth / 2)
    }
}

// ── Kelime/cümle durum kartı ─────────────────────────────────────────────────

struct WordStatusCard: View {
    let turkish: String
    let english: String
    let isLearned: Bool

    private var color: Color { isLearned ? AppTheme.correct : AppTheme.wrong }

    var body: some View {
        HStack(spacing: AppConstants.paddingM) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: isLearned ? "checkmark" : "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(turkish)
                    .appFont(AppConstants.fontXL, weight: .bold)
                    .foregroundStyle(AppTheme.onSurface)
                Text(english)
                    .appFont(AppConstants.fontL)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }

            Spacer()

            SpeakButton(text: english, size: 15)
        }
        .padding(AppConstants.paddingM)
        .background(AppTheme.surfaceContainer, in: RoundedRectangle(cornerRadius: AppConstants.radiusL))
        .padding(.bottom, AppConstants.paddingXS)
    }
}
