import ComposableArchitecture
import Foundation
import GamificationDomain

public extension GamificationProfileRepository {
    static let preview = GamificationProfileRepository(
        load: {
            GamificationProfile(
                currentStreak: 5,
                longestStreak: 12,
                totalPoints: 320,
                lastActivityDate: Date(),
                lastEvaluatedDate: Date(),
                rewardEvents: [
                    RewardEvent(kind: .dailyEntry, earnedAt: Date()),
                    RewardEvent(kind: .streakMilestone3, earnedAt: Date().addingTimeInterval(-3_600 * 48)),
                ],
                unlockedMilestones: [.streakMilestone3],
                unlockedAchievements: [.firstSteps, .earlyBird],
                lastNotifiedFinancialLevel: .bronze,
                activeWeeklyChallenge: WeeklyChallenge(
                    kind: .dailyStreak,
                    weekStart: Date(),
                    currentProgress: 4
                )
            )
        },
        save: { _ in },
        clear: {}
    )
}

private enum GamificationProfileRepositoryKey: DependencyKey {
    static let liveValue = GamificationProfileRepository.empty
    static let previewValue = GamificationProfileRepository.preview
    static let testValue = GamificationProfileRepository.empty
}

public extension DependencyValues {
    var gamificationProfileRepository: GamificationProfileRepository {
        get { self[GamificationProfileRepositoryKey.self] }
        set { self[GamificationProfileRepositoryKey.self] = newValue }
    }
}
