import SwiftUI

/// Hata durumu görünümü — yeniden dene + opsiyonel ana sayfa butonu
struct AppErrorState: View {
    let title: String
    let message: String
    let onRetry: () -> Void
    var onGoHome: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 54))
                .foregroundStyle(AppTheme.error)
            Spacer().frame(height: AppConstants.paddingM)
            Text(title)
                .appFont(22, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            Spacer().frame(height: AppConstants.paddingS)
            Text(message)
                .appFont(AppConstants.fontM)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Spacer().frame(height: AppConstants.paddingL)
            Button("Tekrar Dene", action: onRetry)
                .buttonStyle(FilledAppButtonStyle())
            if let onGoHome {
                Spacer().frame(height: AppConstants.paddingS)
                Button("Ana Sayfa", action: onGoHome)
                    .buttonStyle(TonalAppButtonStyle())
            }
        }
        .padding(AppConstants.paddingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Boş durum görünümü
struct AppEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 54))
                .foregroundStyle(AppTheme.primary)
            Spacer().frame(height: AppConstants.paddingM)
            Text(title)
                .appFont(22, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            Spacer().frame(height: AppConstants.paddingS)
            Text(message)
                .appFont(AppConstants.fontM)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(AppConstants.paddingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ── Buton stilleri — Flutter FilledButton / FilledButton.tonal karşılığı ─────
// neden ButtonStyle: her butonda aynı yükseklik/radius tekrarı yerine tek tanım

struct FilledAppButtonStyle: ButtonStyle {
    var background: Color = AppTheme.primary
    var foreground: Color = .white
    var height: CGFloat = AppConstants.buttonHeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(AppConstants.fontL, weight: .bold)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(background, in: RoundedRectangle(cornerRadius: AppConstants.radiusM))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct TonalAppButtonStyle: ButtonStyle {
    var height: CGFloat = AppConstants.buttonHeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(AppConstants.fontL, weight: .bold)
            .foregroundStyle(AppTheme.onSecondaryContainer)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(AppTheme.secondaryContainer, in: RoundedRectangle(cornerRadius: AppConstants.radiusM))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
