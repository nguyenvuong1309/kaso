import ComposableArchitecture
import GamificationDomain
import KasoDesignSystem
import SwiftUI

private func sampleProgresses(
    unlocked: Set<AchievementKind>,
    streak: Int,
    points: Int
) -> [AchievementProgress] {
    AchievementKind.allCases.map { kind in
        let isUnlocked = unlocked.contains(kind)
        let raw: Int = switch kind {
        case .firstSteps:
            isUnlocked ? 1 : 0
        case .weekWarrior, .monthlyMaster, .centuryClub:
            streak
        case .noSpendNovice, .noSpendChampion:
            isUnlocked ? kind.targetValue : min(2, kind.targetValue - 1)
        case .budgetGuardian:
            isUnlocked ? kind.targetValue : 2
        case .categoryCollector:
            isUnlocked ? kind.targetValue : 3
        case .dualLogger, .earlyBird, .nightOwl:
            isUnlocked ? 1 : 0
        case .rewardCollector, .eliteCollector:
            points
        }
        return AchievementProgress(
            kind: kind,
            currentValue: raw,
            isUnlocked: isUnlocked || raw >= kind.targetValue
        )
    }
}

#Preview("Light") {
    GamificationView(
        store: Store(
            initialState: GamificationFeature.State(
                profile: GamificationProfile(
                    currentStreak: 8,
                    longestStreak: 21,
                    totalPoints: 540,
                    lastActivityDate: Date(),
                    lastEvaluatedDate: Date(),
                    rewardEvents: [
                        RewardEvent(kind: .dailyEntry, earnedAt: Date()),
                        RewardEvent(
                            kind: .streakMilestone7,
                            earnedAt: Date().addingTimeInterval(-3_600 * 24)
                        ),
                        RewardEvent(
                            kind: .noSpendDay,
                            earnedAt: Date().addingTimeInterval(-3_600 * 24 * 2)
                        ),
                    ],
                    unlockedMilestones: [.streakMilestone3, .streakMilestone7],
                    unlockedAchievements: [.firstSteps, .weekWarrior, .earlyBird, .rewardCollector],
                    lastNotifiedFinancialLevel: .bronze,
                    activeWeeklyChallenge: WeeklyChallenge(
                        kind: .categoryVariety,
                        weekStart: Date(),
                        currentProgress: 3
                    )
                ),
                referenceDate: Date(),
                newlyEarnedEvents: [
                    RewardEvent(kind: .dailyEntry, earnedAt: Date()),
                ],
                achievementProgresses: sampleProgresses(
                    unlocked: [.firstSteps, .weekWarrior, .earlyBird, .rewardCollector],
                    streak: 21,
                    points: 540
                ),
                financialLevelProgress: FinancialLevelProgress(totalPoints: 540)
            )
        ) {
            GamificationFeature()
        } withDependencies: {
            $0.gamificationProfileRepository = .preview
            $0.gamificationContextClient = .preview
        }
    )
}

#Preview("Dark") {
    GamificationView(
        store: Store(
            initialState: GamificationFeature.State(
                profile: GamificationProfile(
                    currentStreak: 35,
                    longestStreak: 65,
                    totalPoints: 6_500,
                    unlockedMilestones: [
                        .streakMilestone3, .streakMilestone7, .streakMilestone30,
                    ],
                    unlockedAchievements: [
                        .firstSteps, .weekWarrior, .monthlyMaster, .noSpendNovice,
                        .budgetGuardian, .categoryCollector, .dualLogger,
                        .earlyBird, .rewardCollector, .eliteCollector,
                    ],
                    lastNotifiedFinancialLevel: .platinum,
                    activeWeeklyChallenge: WeeklyChallenge(
                        kind: .dailyStreak,
                        weekStart: Date(),
                        currentProgress: 7,
                        completedAt: Date()
                    )
                ),
                achievementProgresses: sampleProgresses(
                    unlocked: [
                        .firstSteps, .weekWarrior, .monthlyMaster, .noSpendNovice,
                        .budgetGuardian, .categoryCollector, .dualLogger,
                        .earlyBird, .rewardCollector, .eliteCollector,
                    ],
                    streak: 65,
                    points: 6_500
                ),
                financialLevelProgress: FinancialLevelProgress(totalPoints: 6_500)
            )
        ) {
            GamificationFeature()
        } withDependencies: {
            $0.gamificationProfileRepository = .preview
            $0.gamificationContextClient = .preview
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    GamificationView(
        store: Store(
            initialState: GamificationFeature.State(
                profile: GamificationProfile(
                    currentStreak: 4,
                    longestStreak: 9,
                    totalPoints: 180,
                    unlockedAchievements: [.firstSteps],
                    lastNotifiedFinancialLevel: .sprout,
                    activeWeeklyChallenge: WeeklyChallenge(
                        kind: .incomeLogger,
                        weekStart: Date(),
                        currentProgress: 0
                    )
                ),
                achievementProgresses: sampleProgresses(
                    unlocked: [.firstSteps],
                    streak: 9,
                    points: 180
                ),
                financialLevelProgress: FinancialLevelProgress(totalPoints: 180)
            )
        ) {
            GamificationFeature()
        } withDependencies: {
            $0.gamificationProfileRepository = .preview
            $0.gamificationContextClient = .preview
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
