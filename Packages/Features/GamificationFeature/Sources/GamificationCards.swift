import GamificationDomain
import KasoDesignSystem
import SwiftUI

struct GamificationStreakCard: View {
    let profile: GamificationProfile
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("gamification.streak.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            HStack(spacing: Spacing.lg) {
                StreakRing(
                    progress: profile.progressToNextLevel,
                    streak: profile.currentStreak,
                    reduceMotion: reduceMotion
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(LocalizedStringKey(profile.level.nameKey), bundle: .module)
                        .font(.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                    Text(LocalizedStringKey(profile.level.descriptionKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)

                    if let next = profile.nextLevel,
                       let days = profile.daysToNextLevel {
                        let nextName = NSLocalizedString(
                            next.nameKey,
                            bundle: .module,
                            comment: ""
                        )
                        Text(
                            "gamification.streak.nextLevel \(days) \(nextName)",
                            bundle: .module
                        )
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.accent)
                    } else {
                        Text("gamification.streak.maxLevel", bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.positive)
                    }
                }
            }
        }
    }
}

struct GamificationPointsCard: View {
    let profile: GamificationProfile
    let earnedToday: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("gamification.points.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("\(profile.totalPoints)")
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.accent)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            HStack(spacing: Spacing.md) {
                MetricBlock(
                    titleKey: "gamification.points.today",
                    value: "+\(earnedToday)"
                )
                MetricBlock(
                    titleKey: "gamification.streak.longest",
                    value: "\(profile.longestStreak)"
                )
            }
        }
    }
}

struct GamificationRewardsCard: View {
    let events: [RewardEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("gamification.rewards.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if events.isEmpty {
                Text("gamification.rewards.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(events) { event in
                    GamificationRewardRow(event: event)
                }
            }
        }
    }
}

struct GamificationMilestonesCard: View {
    let unlocked: Set<RewardEventKind>

    private static let milestones: [RewardEventKind] = [
        .streakMilestone3,
        .streakMilestone7,
        .streakMilestone30,
        .streakMilestone100,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("gamification.milestones.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md),
                ],
                spacing: Spacing.md
            ) {
                ForEach(Self.milestones) { kind in
                    GamificationMilestoneTile(
                        kind: kind,
                        isUnlocked: unlocked.contains(kind)
                    )
                }
            }
        }
    }
}

struct StreakRing: View {
    let progress: Double
    let streak: Int
    let reduceMotion: Bool

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.kaso.surfacePrimary,
                    style: StrokeStyle(lineWidth: Layout.ringLineWidth)
                )
            Circle()
                .trim(from: 0, to: max(0.001, animatedProgress))
                .stroke(
                    LinearGradient(
                        colors: [Color.kaso.accent, Color.kaso.positive],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(
                        lineWidth: Layout.ringLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(streak)")
                    .font(.kaso.numericLarge)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .lineLimit(1)
                Text("gamification.streak.daysLabel", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
        .frame(width: Layout.ringSize, height: Layout.ringSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("gamification.streak.accessibility \(streak)", bundle: .module))
        .onAppear {
            updateProgress(animated: !reduceMotion)
        }
        .onChange(of: progress) { _, _ in
            updateProgress(animated: !reduceMotion)
        }
    }

    private func updateProgress(animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedProgress = progress
            }
        } else {
            animatedProgress = progress
        }
    }
}

struct GamificationRewardRow: View {
    let event: RewardEvent

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: event.kind.symbolName)
                .foregroundStyle(Color.kaso.accent)
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(event.kind.titleKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(event.earnedAt.formatted(.dateTime.day().month().hour().minute()))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            Text("+\(event.points)")
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.positive)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
    }
}

struct GamificationMilestoneTile: View {
    let kind: RewardEventKind
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: kind.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.milestoneIconSize, height: Layout.milestoneIconSize)
                .foregroundStyle(
                    isUnlocked ? Color.kaso.accent : Color.kaso.textSecondary
                )
                .opacity(isUnlocked ? 1 : Layout.lockedOpacity)

            Text(LocalizedStringKey(kind.titleKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
                .multilineTextAlignment(.center)

            Text("+\(kind.points)")
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(
                    isUnlocked ? Color.kaso.accent : Color.kaso.surfacePrimary,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(milestoneAccessibilityLabel)
    }

    private var milestoneAccessibilityLabel: Text {
        let title = NSLocalizedString(
            kind.titleKey,
            bundle: .module,
            comment: ""
        )
        if isUnlocked {
            return Text("gamification.milestones.unlocked \(title)", bundle: .module)
        } else {
            return Text("gamification.milestones.locked \(title)", bundle: .module)
        }
    }
}

private struct MetricBlock: View {
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
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension RewardEventKind {
    var symbolName: String {
        switch self {
        case .dailyEntry:
            "checkmark.circle.fill"
        case .streakMilestone3:
            "flame.fill"
        case .streakMilestone7:
            "flame.circle.fill"
        case .streakMilestone30:
            "trophy.fill"
        case .streakMilestone100:
            "crown.fill"
        case .noSpendDay:
            "leaf.fill"
        case .budgetRespected:
            "shield.lefthalf.filled"
        case .weeklyChallengeCompleted:
            "calendar.badge.checkmark"
        }
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
    static let ringSize: CGFloat = 140
    static let ringLineWidth: CGFloat = 12
    static let milestoneIconSize: CGFloat = 40
    static let lockedOpacity: Double = 0.3
}
