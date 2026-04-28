import GamificationDomain
import KasoDesignSystem
import SwiftUI

struct GamificationAchievementsCard: View {
    let progresses: [AchievementProgress]
    let unlockedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("gamification.achievements.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Text(
                    "gamification.achievements.count \(unlockedCount) \(progresses.count)",
                    bundle: .module
                )
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            }

            if progresses.isEmpty {
                Text("gamification.achievements.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(AchievementCategory.allCases) { category in
                    let group = progresses.filter { $0.kind.category == category }
                    if !group.isEmpty {
                        AchievementCategorySection(category: category, progresses: group)
                    }
                }
            }
        }
    }
}

struct AchievementCategorySection: View {
    let category: AchievementCategory
    let progresses: [AchievementProgress]

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(LocalizedStringKey(category.titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.accent)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(progresses) { progress in
                    AchievementTile(progress: progress)
                }
            }
        }
    }
}

struct AchievementTile: View {
    let progress: AchievementProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: progress.kind.symbolName)
                    .font(.system(size: AchievementLayout.iconFontSize, weight: .semibold))
                    .foregroundStyle(
                        progress.isUnlocked
                            ? Color.kaso.accent
                            : Color.kaso.textSecondary
                    )
                    .opacity(progress.isUnlocked ? 1 : AchievementLayout.lockedOpacity)
                    .frame(
                        width: AchievementLayout.iconBoxSize,
                        height: AchievementLayout.iconBoxSize
                    )
                    .background(
                        Circle()
                            .fill(
                                progress.isUnlocked
                                    ? Color.kaso.accent.opacity(0.18)
                                    : Color.kaso.textSecondary.opacity(0.12)
                            )
                    )

                Spacer(minLength: 0)

                if progress.isUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.positive)
                }
            }

            Text(LocalizedStringKey(progress.kind.titleKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(LocalizedStringKey(progress.kind.descriptionKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            AchievementProgressBar(progress: progress)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(
                    progress.isUnlocked
                        ? Color.kaso.accent.opacity(0.4)
                        : Color.kaso.textSecondary.opacity(0.18),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityLabel: Text {
        let title = NSLocalizedString(
            progress.kind.titleKey,
            bundle: .module,
            comment: ""
        )
        return Text(
            progress.isUnlocked
                ? "gamification.achievements.unlocked \(title)"
                : "gamification.achievements.locked \(title)",
            bundle: .module
        )
    }

    private var accessibilityValue: Text {
        Text(
            "gamification.achievements.progress \(progress.displayValue) \(progress.targetValue)",
            bundle: .module
        )
    }
}

struct AchievementProgressBar: View {
    let progress: AchievementProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                                colors: progress.isUnlocked
                                    ? [Color.kaso.accent, Color.kaso.positive]
                                    : [
                                        Color.kaso.accent.opacity(0.6),
                                        Color.kaso.accent.opacity(0.9),
                                    ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, proxy.size.width * animatedRatio))
                }
            }
            .frame(height: AchievementLayout.barHeight)

            Text("\(progress.displayValue)/\(progress.targetValue)")
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
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
            withAnimation(.easeInOut(duration: 0.45)) {
                animatedRatio = progress.ratio
            }
        } else {
            animatedRatio = progress.ratio
        }
    }
}

private enum AchievementLayout {
    static let iconFontSize: CGFloat = 20
    static let iconBoxSize: CGFloat = 36
    static let lockedOpacity: Double = 0.5
    static let barHeight: CGFloat = 6
}
