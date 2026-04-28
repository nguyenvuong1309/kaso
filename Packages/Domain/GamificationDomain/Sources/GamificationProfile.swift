import Foundation

public struct GamificationProfile: Codable, Equatable, Sendable {
    public static let weeklyChallengeHistoryLimit = 12

    public var currentStreak: Int
    public var longestStreak: Int
    public var totalPoints: Int
    public var lastActivityDate: Date?
    public var lastEvaluatedDate: Date?
    public var rewardEvents: [RewardEvent]
    public var unlockedMilestones: Set<RewardEventKind>
    public var unlockedAchievements: Set<AchievementKind>
    public var lastNotifiedFinancialLevel: FinancialLevel?
    public var activeWeeklyChallenge: WeeklyChallenge?
    public var completedWeeklyChallenges: [WeeklyChallenge]

    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalPoints: Int = 0,
        lastActivityDate: Date? = nil,
        lastEvaluatedDate: Date? = nil,
        rewardEvents: [RewardEvent] = [],
        unlockedMilestones: Set<RewardEventKind> = [],
        unlockedAchievements: Set<AchievementKind> = [],
        lastNotifiedFinancialLevel: FinancialLevel? = nil,
        activeWeeklyChallenge: WeeklyChallenge? = nil,
        completedWeeklyChallenges: [WeeklyChallenge] = []
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalPoints = totalPoints
        self.lastActivityDate = lastActivityDate
        self.lastEvaluatedDate = lastEvaluatedDate
        self.rewardEvents = rewardEvents
        self.unlockedMilestones = unlockedMilestones
        self.unlockedAchievements = unlockedAchievements
        self.lastNotifiedFinancialLevel = lastNotifiedFinancialLevel
        self.activeWeeklyChallenge = activeWeeklyChallenge
        self.completedWeeklyChallenges = completedWeeklyChallenges
    }

    private enum CodingKeys: String, CodingKey {
        case currentStreak
        case longestStreak
        case totalPoints
        case lastActivityDate
        case lastEvaluatedDate
        case rewardEvents
        case unlockedMilestones
        case unlockedAchievements
        case lastNotifiedFinancialLevel
        case activeWeeklyChallenge
        case completedWeeklyChallenges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        lastActivityDate = try container.decodeIfPresent(Date.self, forKey: .lastActivityDate)
        lastEvaluatedDate = try container.decodeIfPresent(Date.self, forKey: .lastEvaluatedDate)
        rewardEvents = try container.decodeIfPresent([RewardEvent].self, forKey: .rewardEvents) ?? []
        unlockedMilestones = try container.decodeIfPresent(
            Set<RewardEventKind>.self,
            forKey: .unlockedMilestones
        ) ?? []
        unlockedAchievements = try container.decodeIfPresent(
            Set<AchievementKind>.self,
            forKey: .unlockedAchievements
        ) ?? []
        lastNotifiedFinancialLevel = try container.decodeIfPresent(
            FinancialLevel.self,
            forKey: .lastNotifiedFinancialLevel
        )
        activeWeeklyChallenge = try container.decodeIfPresent(
            WeeklyChallenge.self,
            forKey: .activeWeeklyChallenge
        )
        completedWeeklyChallenges = try container.decodeIfPresent(
            [WeeklyChallenge].self,
            forKey: .completedWeeklyChallenges
        ) ?? []
    }

    public var level: StreakLevel {
        StreakLevel.level(for: currentStreak)
    }

    public var nextLevel: StreakLevel? {
        level.nextLevel
    }

    public var daysToNextLevel: Int? {
        guard let next = nextLevel else {
            return nil
        }
        return max(next.minStreakDays - currentStreak, 0)
    }

    public var progressToNextLevel: Double {
        guard let next = nextLevel else {
            return 1
        }

        let lower = Double(level.minStreakDays)
        let upper = Double(next.minStreakDays)
        guard upper > lower else {
            return 1
        }

        let progress = (Double(currentStreak) - lower) / (upper - lower)
        return min(max(progress, 0), 1)
    }

    public var financialLevel: FinancialLevel {
        FinancialLevel.level(for: totalPoints)
    }

    public var financialLevelProgress: FinancialLevelProgress {
        FinancialLevelProgress(totalPoints: totalPoints)
    }
}
