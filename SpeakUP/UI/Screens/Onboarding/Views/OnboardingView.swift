import SwiftUI

/// İlk açılış tanıtım ekranı — 3 sayfalık kaydırmalı akış
struct OnboardingView: View {
    /// Onboarding tamamlanınca çağrılır — ana akışa geçilir
    let onComplete: () -> Void

    @State private var currentIndex = 0

    private struct Item {
        let title: String
        let description: String
        let icon: String
    }

    private static let items = [
        Item(
            title: "\(AppConstants.appDisplayName)'a Hoş Geldin",
            description: "Günlük kısa tekrarlarla kelime ve cümle öğrenimini hızlandır.",
            icon: "graduationcap.fill"
        ),
        Item(
            title: "Quiz + Cümle Kur",
            description: "Önce quiz ile kelimeleri pekiştir, sonra cümle kurarak aktif kullan.",
            icon: "questionmark.circle.fill"
        ),
        Item(
            title: "İlerlemeni Takip Et",
            description: "Yanlışlarını gör, zayıf kaldığın kelimeleri tekrar et, seriyi koru.",
            icon: "chart.line.uptrend.xyaxis"
        ),
    ]

    private var isLast: Bool { currentIndex == Self.items.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Geç", action: onComplete)
                    .appFont(AppConstants.fontL, weight: .semibold)
                    .foregroundStyle(AppTheme.primary)
            }

            TabView(selection: $currentIndex) {
                ForEach(Array(Self.items.enumerated()), id: \.offset) { index, item in
                    onboardingCard(item).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeOut(duration: 0.26), value: currentIndex)

            // Sayfa göstergesi — aktif nokta genişler
            HStack(spacing: 8) {
                ForEach(0..<Self.items.count, id: \.self) { index in
                    Capsule()
                        .fill(currentIndex == index ? AppTheme.primary : AppTheme.primary.opacity(0.25))
                        .frame(width: currentIndex == index ? 18 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.22), value: currentIndex)
                }
            }
            Spacer().frame(height: AppConstants.paddingL)

            Button(isLast ? "Başla" : "Devam Et") {
                if isLast {
                    onComplete()
                } else {
                    currentIndex += 1
                }
            }
            .buttonStyle(FilledAppButtonStyle())
        }
        .padding(AppConstants.paddingL)
        .background(AppTheme.surface)
    }

    private func onboardingCard(_ item: Item) -> some View {
        VStack(spacing: 0) {
            AppIconImage(size: 96, cornerRadius: 24)
            Spacer().frame(height: AppConstants.paddingXL)
            Image(systemName: item.icon)
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.primary)
            Spacer().frame(height: AppConstants.paddingM)
            Text(item.title)
                .appFont(24, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
                .multilineTextAlignment(.center)
            Spacer().frame(height: AppConstants.paddingS)
            Text(item.description)
                .appFont(AppConstants.fontXL)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, AppConstants.paddingL)
    }
}
