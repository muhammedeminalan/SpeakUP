import SwiftUI

/// Uygulama kökü — onboarding kapısı + navigasyon yığını + rota eşlemesi.
/// Flutter'daki AppRoot + GoRouter yapısının karşılığı.
struct AppRootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(Router.self) private var router

    // neden AppStorage: onboarding sadece ilk açılışta gösterilsin
    @AppStorage(AppConstants.onboardingSeenKey) private var onboardingSeen = false

    var body: some View {
        @Bindable var router = router

        Group {
            if onboardingSeen {
                NavigationStack(path: $router.path) {
                    ChapterListView()
                        .navigationDestination(for: Router.Destination.self) { destination in
                            view(for: destination)
                        }
                }
            } else {
                OnboardingView { onboardingSeen = true }
            }
        }
        // Kullanıcı tema tercihi — nil ise sistem teması takip edilir
        .preferredColorScheme(settings.themeMode.colorScheme)
    }

    // Rota → görünüm eşlemesi tek merkezde — Flutter'daki app_router karşılığı
    @ViewBuilder
    private func view(for destination: Router.Destination) -> some View {
        switch destination {
        case let .chapterDashboard(chapter):
            ChapterDashboardView(chapter: chapter)
        case let .wordQuiz(payload):
            WordQuizView(payload: payload)
        case let .wordQuizResult(payload):
            WordQuizResultView(payload: payload)
        case let .sentenceBuilder(payload):
            SentenceBuilderView(payload: payload)
        case let .sentenceResult(payload):
            SentenceResultView(payload: payload)
        case let .progress(payload):
            ChapterProgressView(payload: payload)
        case .settings:
            SettingsView()
        }
    }
}
