import GamificationDomain
import KasoDesignSystem
import SwiftUI

struct GamificationFinancialLevelCard: View {
    let progress: FinancialLevelProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("gamification.financialLevel.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            HStack(alignment: .top, spacing: Spacing.lg) {
                FinancialLevelBadge(level: progress.level)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(progress.level.nameKey), bundle: .module)
                        .font(.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                    Text(LocalizedStringKey(progress.level.descriptionKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(LocalizedStringKey(progress.level.perkKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.accent)
                }

                Spacer(minLength: 0)
            }

            FinancialLevelProgressBar(progress: progress, reduceMotion: reduceMotion)

            HStack(spacing: Spacing.md) {
                FinancialLevelMetric(
                    titleKey: "gamification.financialLevel.totalXp",
                    value: "\(progress.totalPoints)"
                )
                FinancialLevelMetric(
                    titleKey: nextOrCurrentTitleKey,
                    value: nextOrCurrentValue
                )
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var nextOrCurrentTitleKey: String {
        progress.isMaxLevel
            ? "gamification.financialLevel.maxedTitle"
            : "gamification.financialLevel.toNext"
    }

    private var nextOrCurrentValue: String {
        if progress.isMaxLevel {
            "✓"
        } else {
            "\(progress.pointsNeededForNext ?? 0)"
        }
    }
}

struct FinancialLevelBadge: View {
    let level: FinancialLevel

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: badgeColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: BadgeLayout.size,
                    height: BadgeLayout.size
                )
                .shadow(
                    color: shadowColor.opacity(0.35),
                    radius: BadgeLayout.shadowRadius,
                    x: 0,
                    y: 2
                )
            Image(systemName: level.symbolName)
                .font(.system(size: BadgeLayout.iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var badgeColors: [Color] {
        switch level {
        case .sprout:
            [Color.kaso.positive.opacity(0.7), Color.kaso.positive]
        case .bronze:
            [Color(red: 0.71, green: 0.46, blue: 0.27), Color(red: 0.55, green: 0.34, blue: 0.18)]
        case .silver:
            [Color(red: 0.78, green: 0.79, blue: 0.81), Color(red: 0.55, green: 0.57, blue: 0.60)]
        case .gold:
            [Color(red: 1.0, green: 0.83, blue: 0.36), Color(red: 0.83, green: 0.59, blue: 0.13)]
        case .platinum:
            [Color(red: 0.85, green: 0.88, blue: 0.92), Color(red: 0.60, green: 0.66, blue: 0.74)]
        case .diamond:
            [Color(red: 0.62, green: 0.91, blue: 1.0), Color(red: 0.18, green: 0.55, blue: 0.86)]
        case .legend:
            [Color.kaso.accent, Color(red: 0.55, green: 0.21, blue: 0.85)]
        }
    }

    private var shadowColor: Color {
        badgeColors.last ?? Color.kaso.accent
    }

    private enum BadgeLayout {
        static let size: CGFloat = 64
        static let iconSize: CGFloat = 28
        static let shadowRadius: CGFloat = 6
    }
}

struct FinancialLevelProgressBar: View {
    let progress: FinancialLevelProgress
    let reduceMotion: Bool
    @State private var animatedRatio: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.kaso.textSecondary.opacity(0.15))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.kaso.accent, Color.kaso.positive],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * animatedRatio))
                }
            }
            .frame(height: BarLayout.height)

            HStack {
                Text("\(progress.totalPoints)")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                if let next = progress.nextLevel {
                    Text("\(next.minimumPoints)")
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }
        }
        .onAppear {
            update(animated: !reduceMotion)
        }
        .onChange(of: progress.ratio) { _, _ in
            update(animated: !reduceMotion)
        }
    }

    private func update(animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedRatio = progress.ratio
            }
        } else {
            animatedRatio = progress.ratio
        }
    }

    private enum BarLayout {
        static let height: CGFloat = 8
    }
}

private struct FinancialLevelMetric: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
