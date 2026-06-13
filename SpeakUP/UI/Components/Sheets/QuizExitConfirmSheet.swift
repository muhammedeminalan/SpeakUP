import SwiftUI

/// Quiz'den çıkış onayı — Flutter'daki bottom sheet'in karşılığı.
/// onConfirm yalnızca "Çık" seçilirse çağrılır.
struct QuizExitConfirmSheet: View {
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AppTheme.error.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.error)
            }
            Spacer().frame(height: AppConstants.paddingL)

            Text("Çıkmak istiyor musun?")
                .appFont(AppConstants.fontXL, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            Spacer().frame(height: AppConstants.paddingS)

            Text("Çıkarsan bu oturumdaki ilerleme silinir.")
                .appFont(AppConstants.fontM)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            Spacer().frame(height: AppConstants.paddingXXL)

            Button("Devam Et") { dismiss() }
                .buttonStyle(FilledAppButtonStyle(height: 48))
            Spacer().frame(height: AppConstants.paddingM)

            Button("Çık") {
                dismiss()
                onConfirm()
            }
            .buttonStyle(FilledAppButtonStyle(background: AppTheme.error, height: 48))
        }
        .padding(.horizontal, AppConstants.paddingXL)
        .padding(.top, AppConstants.paddingXL)
        .padding(.bottom, AppConstants.paddingXL)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.surfaceContainer)
    }
}
