import SwiftUI

@main
struct SpeakUPApp: App {
    // neden State + opsiyonel: bağımlılık kurulumu (storage açılışı) başarısız
    // olabilir; hata durumunda crash yerine hata ekranı gösterilir
    @State private var dependencies: AppDependencies?
    @State private var bootstrapError: String?

    var body: some Scene {
        WindowGroup {
            if let dependencies {
                AppRootView()
                    .environment(dependencies)
                    .environment(dependencies.settings)
                    .environment(dependencies.tts)
                    .environment(Router())
            } else if let bootstrapError {
                BootstrapErrorView(message: bootstrapError)
            } else {
                // Kurulum tamamlanana dek marka renkli açılış ekranı
                BootstrapSplashView()
                    .task {
                        do {
                            dependencies = try AppDependencies()
                        } catch {
                            bootstrapError = error.localizedDescription
                        }
                    }
            }
        }
    }
}

// ── Açılış ve hata ekranları — Flutter'daki BootstrapGate karşılığı ──────────

private struct BootstrapSplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0E7BFF), Color(hex: 0x0A3EBE)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                AppIconImage(size: 92, cornerRadius: 26)
                Text(AppConstants.appDisplayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                SwiftUI.ProgressView()
                    .tint(.white)
            }
        }
    }
}

private struct BootstrapErrorView: View {
    let message: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0E7BFF), Color(hex: 0x0A3EBE)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                AppIconImage(size: 92, cornerRadius: 26)
                Text(AppConstants.appDisplayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Başlatma hatası oluştu.\nUygulamayı yeniden başlat.\n\(message)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }
}
