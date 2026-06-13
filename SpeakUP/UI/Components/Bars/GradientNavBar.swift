import SwiftUI

/// Tüm sayfalarda kullanılan ortak gradient üst bar — Flutter GradientAppBar karşılığı.
/// neden custom view: SwiftUI toolbar'ı gradient arka planı ve tam kontrolü vermiyor;
/// tek widget'tan yönetilince renk/stil değişiklikleri tek yerden yapılır.
struct GradientNavBar<Trailing: View>: View {
    let title: String
    var showBack = true
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        showBack: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.showBack = showBack
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        ZStack {
            HStack {
                if showBack {
                    Button {
                        if let onBack { onBack() } else { dismiss() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
                trailing()
            }

            // neden ZStack ortası: başlık buton sayısından bağımsız ortalanır
            Text(title)
                .appFont(18, weight: .bold)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, AppConstants.paddingXS)
        .frame(height: 44)
        .background(alignment: .bottom) {
            // neden ignoresSafeArea: gradient status bar'ın arkasına da uzanır
            AppColors.appBarGradient.ignoresSafeArea(edges: .top)
        }
    }
}
