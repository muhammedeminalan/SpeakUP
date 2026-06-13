import SwiftUI

/// Ana sayfa — hero kart + bölüm listesi
struct ChapterListView: View {
    @Environment(Router.self) private var router
    @Environment(AppDependencies.self) private var deps
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: ChapterListViewModel?

    var body: some View {
        ZStack {
            AppColors.pageBackground(isDark: colorScheme == .dark)
                .ignoresSafeArea()

            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard viewModel == nil else { return }
            let vm = ChapterListViewModel(getChapters: deps.getChapters)
            viewModel = vm
            await vm.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel {
            switch viewModel.state {
            case .loading:
                loadingView
            case let .error(message):
                AppErrorState(
                    title: "Bölümler Yüklenemedi",
                    message: message,
                    onRetry: { Task { await viewModel.load() } }
                )
            case let .loaded(chapters):
                if chapters.isEmpty {
                    AppEmptyState(
                        icon: "book.fill",
                        title: "Bölüm Bulunamadı",
                        message: "Henüz gösterilecek bölüm yok."
                    )
                } else {
                    chapterList(chapters)
                }
            }
        } else {
            loadingView
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppConstants.paddingM) {
            AppIconImage(size: 76, cornerRadius: 20)
            Text("Bölümler hazırlanıyor...")
                .appFont(AppConstants.fontL, weight: .bold)
                .foregroundStyle(AppTheme.onSurface)
            SwiftUI.ProgressView()
                .controlSize(.large)
                .tint(AppTheme.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func chapterList(_ chapters: [Chapter]) -> some View {
        let totalWords = chapters.reduce(0) { $0 + $1.words.count }
        let totalSentences = chapters.reduce(0) { $0 + $1.sentences.count }

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroCard(totalWords: totalWords, totalSentences: totalSentences, chapterCount: chapters.count)
                    .padding(.horizontal, AppConstants.paddingL)
                    .padding(.top, AppConstants.paddingM)
                    .padding(.bottom, AppConstants.paddingL)

                Text("Öğrenme Yolun")
                    .appFont(20, weight: .bold)
                    .foregroundStyle(AppTheme.onSurface)
                    .padding(.horizontal, AppConstants.paddingL)
                    .padding(.bottom, AppConstants.paddingS)

                VStack(spacing: AppConstants.paddingM) {
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        ChapterListCard(chapter: chapter, index: index) {
                            router.navigate(to: .chapterDashboard(chapter))
                        }
                    }
                }
                .padding(.horizontal, AppConstants.paddingL)
                .padding(.bottom, AppConstants.paddingXXL)
            }
        }
    }

    private func heroCard(totalWords: Int, totalSentences: Int, chapterCount: Int) -> some View {
        VStack(spacing: AppConstants.paddingM) {
            HStack(spacing: AppConstants.paddingS) {
                AppIconImage(size: 44, cornerRadius: 14)
                Text(AppConstants.appDisplayName)
                    .appFont(26, weight: .bold)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    router.navigate(to: .settings)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.22), in: Circle())
                }
            }

            Text("Bugün bir bölüm seç ve seriyi devam ettir.")
                .appFont(AppConstants.fontL)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppConstants.paddingS) {
                HeroStatTile(icon: "book.fill", label: "Kelime", value: "\(totalWords)")
                HeroStatTile(icon: "bubble.left", label: "Cümle", value: "\(totalSentences)")
                HeroStatTile(icon: "square.grid.2x2.fill", label: "Bölüm", value: "\(chapterCount)")
            }
        }
        .padding(AppConstants.paddingL)
        .background(AppColors.heroGradient, in: RoundedRectangle(cornerRadius: AppConstants.radiusXL))
        .shadow(color: Color(hex: 0x4454E8).opacity(0.3), radius: 13, y: 12)
    }
}

// ── Ortak küçük bileşenler ───────────────────────────────────────────────────

/// Hero/başlık kartlarındaki istatistik kutusu — liste ve dashboard'da ortak
struct HeroStatTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
            Text(value)
                .appFont(16, weight: .bold)
                .foregroundStyle(.white)
            Text(label)
                .appFont(11, weight: .semibold)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.paddingS)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: AppConstants.radiusM))
    }
}

/// Bundle'daki uygulama ikonu görseli
struct AppIconImage: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            // neden UIImage ile yükleme: ikon assets katalogda değil, bundle kaynağı
            if let uiImage = UIImage(named: "app_icon") ?? loadFromBundle() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Görsel bulunamazsa marka renkli yedek kutu — boş alan kalmaz
                AppColors.heroGradient
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func loadFromBundle() -> UIImage? {
        guard let url = Bundle.main.url(forResource: "app_icon", withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

// ── Bölüm kartı ──────────────────────────────────────────────────────────────

struct ChapterListCard: View {
    let chapter: Chapter
    let index: Int
    let onTap: () -> Void

    @State private var appeared = false

    private var gradient: [Color] {
        AppColors.chapterGradients[index % AppColors.chapterGradients.count]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppConstants.paddingM) {
                HStack(spacing: AppConstants.paddingS) {
                    Text("\(index + 1)")
                        .appFont(20, weight: .black)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )

                    VStack(alignment: .leading, spacing: 0) {
                        Text(chapter.name)
                            .appFont(22, weight: .bold)
                            .foregroundStyle(AppTheme.onSurface)
                            .lineLimit(1)
                        Text("\(chapter.words.count + chapter.sentences.count) içerik • öğrenmeye devam")
                            .appFont(AppConstants.fontM, weight: .semibold)
                            .foregroundStyle(AppTheme.onSurfaceVariant)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }

                HStack(spacing: AppConstants.paddingS) {
                    statChip(icon: "textformat.abc", label: "\(chapter.words.count) kelime", color: gradient[0])
                    statChip(icon: "bubble.left", label: "\(chapter.sentences.count) cümle", color: gradient[1])
                }
            }
            .padding(AppConstants.paddingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surfaceContainer)
            .overlay(alignment: .leading) {
                Rectangle().fill(gradient[0]).frame(width: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.radiusXL))
        }
        .buttonStyle(.plain)
        // Giriş animasyonu — sırayla yukarı kayarak belirir
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .onAppear {
            withAnimation(.easeOut(duration: Double(min(220 + index * 70, 820)) / 1000)) {
                appeared = true
            }
        }
    }

    private func statChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .appFont(13, weight: .bold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.16), in: Capsule())
    }
}
