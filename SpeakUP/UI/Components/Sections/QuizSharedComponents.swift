import SwiftUI

// Kelime quizi ve cümle kurma ekranlarının ortak parçaları.
// neden tek dosya: Flutter tarafında iki feature'da kopyalanan _ScoreBadge,
// progress başlığı ve sonuç bölümleri burada tekilleştirildi — kod tekrarı yok.

/// ✓ / ✗ skor rozeti
struct ScoreBadge: View {
    let symbol: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(symbol)
                .appFont(AppConstants.fontS, weight: .bold)
            Text("\(count)")
                .appFont(AppConstants.fontXL, weight: .bold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

/// Soru üst bilgisi: ilerleme çubuğu + skorlar + kalan soru sayısı
struct QuizQuestionHeader: View {
    let questionIndex: Int
    let totalQuestions: Int
    let correctCount: Int
    let wrongCount: Int
    let isReadOnly: Bool
    /// "soru" veya "cümle" — read-only etiketinde kullanılır
    var itemLabel: String = "soru"

    var body: some View {
        VStack(spacing: AppConstants.paddingS) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.25))
                    Capsule()
                        .fill(AppTheme.correct)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: AppConstants.progressBarHeight)

            HStack(spacing: AppConstants.paddingS) {
                ScoreBadge(symbol: "✓", count: correctCount, color: AppTheme.correct)
                ScoreBadge(symbol: "✗", count: wrongCount, color: AppTheme.wrong)
                Spacer()
                if isReadOnly {
                    Text("← Geçmiş \(itemLabel)")
                        .appFont(AppConstants.fontS)
                        .italic()
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                } else {
                    Text("\(totalQuestions - questionIndex - 1) kalan")
                        .appFont(AppConstants.fontS)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, AppConstants.paddingXL)
        .padding(.top, AppConstants.paddingM)
    }

    private var progress: CGFloat {
        guard totalQuestions > 0 else { return 0 }
        return CGFloat(questionIndex + 1) / CGFloat(totalQuestions)
    }
}

/// Sonuç ekranı skor bölümü — dairesel skor + yüzde + rozet + XP
struct QuizResultScoreSection: View {
    let correct: Int
    let total: Int
    let xpEarned: Int

    private var percentage: Int {
        total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0
    }

    private var badge: String {
        if percentage == 100 { return "🏆 Mükemmel!" }
        if percentage >= 80 { return "🌟 Harika!" }
        if percentage >= 70 { return "👍 İyi!" }
        if percentage >= 50 { return "💪 Daha çok çalış!" }
        return "📖 Tekrar et!"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(AppTheme.primary, lineWidth: 4)
                VStack(spacing: 2) {
                    Text("\(correct)")
                        .appFont(32, weight: .bold)
                        .foregroundStyle(AppTheme.onSurface)
                    Text("/ \(total)")
                        .appFont(AppConstants.fontS)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }
            .frame(width: 110, height: 110)
            Spacer().frame(height: AppConstants.paddingM)

            Text("%\(percentage) doğru")
                .appFont(AppConstants.fontXL, weight: .semibold)
                .foregroundStyle(AppTheme.primary)
            Spacer().frame(height: AppConstants.paddingS)

            Text(badge)
                .appFont(AppConstants.fontM, weight: .bold)
                .foregroundStyle(AppTheme.onPrimaryContainer)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(AppTheme.primaryContainer, in: Capsule())
            Spacer().frame(height: AppConstants.paddingS)

            Text("+\(xpEarned) XP ⭐")
                .appFont(AppConstants.fontM)
                .foregroundStyle(AppTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.paddingXL)
    }
}

/// "Doğru Cevaplananlar" / "Yanlış Cevaplananlar" bölüm başlığı
struct ResultSectionHeader: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: AppConstants.paddingS) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 16)
            Text(label)
                .appFont(AppConstants.fontM, weight: .bold)
                .foregroundStyle(color)
            Text("\(count)")
                .appFont(AppConstants.fontXS, weight: .bold)
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Spacer()
        }
        .padding(.horizontal, AppConstants.paddingXL)
        .padding(.top, AppConstants.paddingXL)
        .padding(.bottom, AppConstants.paddingS)
    }
}

/// Sol kenarı renkli sonuç kartı zemini
/// neden modifier benzeri yapı: doğru/yanlış kartlarının ortak çerçevesi tek yerde
struct ResultCardContainer<Content: View>: View {
    let accentColor: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
            content()
                .padding(.horizontal, AppConstants.paddingM)
                .padding(.vertical, AppConstants.paddingM)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.radiusM))
        .padding(.bottom, AppConstants.paddingS)
    }
}
