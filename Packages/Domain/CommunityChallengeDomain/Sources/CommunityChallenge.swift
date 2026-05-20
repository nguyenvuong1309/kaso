import Foundation

public enum CommunityChallengeCategory: String, CaseIterable, Sendable, Equatable {
    case noSpend
    case mindfulEating
    case subscriptionCleanup
    case gratitude
    case savingsBoost

    public var labelKey: String { "communityChallenge.category.\(rawValue)" }
    public var iconSystemName: String {
        switch self {
        case .noSpend: "calendar.badge.minus"
        case .mindfulEating: "fork.knife"
        case .subscriptionCleanup: "scissors"
        case .gratitude: "heart"
        case .savingsBoost: "leaf.arrow.circlepath"
        }
    }
}

public enum CommunityChallengeDifficulty: String, Sendable, Equatable {
    case easy
    case medium
    case hard

    public var labelKey: String { "communityChallenge.difficulty.\(rawValue)" }
}

public struct CommunityChallenge: Identifiable, Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let descriptionKey: String
    public let goalKey: String
    public let durationDays: Int
    public let category: CommunityChallengeCategory
    public let difficulty: CommunityChallengeDifficulty

    public init(
        id: String,
        titleKey: String,
        descriptionKey: String,
        goalKey: String,
        durationDays: Int,
        category: CommunityChallengeCategory,
        difficulty: CommunityChallengeDifficulty
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.goalKey = goalKey
        self.durationDays = durationDays
        self.category = category
        self.difficulty = difficulty
    }
}

public struct CommunityChallengeEnrollment: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let challengeID: String
    public let startedAt: Date
    public var checkedInDays: Int
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        challengeID: String,
        startedAt: Date = Date(),
        checkedInDays: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.challengeID = challengeID
        self.startedAt = startedAt
        self.checkedInDays = checkedInDays
        self.isCompleted = isCompleted
    }

    public func progress(durationDays: Int) -> Double {
        guard durationDays > 0 else { return 0 }
        return min(1.0, Double(checkedInDays) / Double(durationDays))
    }

    public func daysRemaining(durationDays: Int, today: Date = Date()) -> Int {
        let elapsed = Calendar.current.dateComponents([.day], from: startedAt, to: today).day ?? 0
        return max(0, durationDays - elapsed)
    }
}
