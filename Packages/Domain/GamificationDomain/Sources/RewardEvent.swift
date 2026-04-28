import Foundation

public enum RewardEventKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case dailyEntry
    case streakMilestone3
    case streakMilestone7
    case streakMilestone30
    case streakMilestone100
    case noSpendDay
    case budgetRespected
    case weeklyChallengeCompleted

    public var id: String {
        rawValue
    }

    public var points: Int {
        switch self {
        case .dailyEntry:
            10
        case .streakMilestone3:
            30
        case .streakMilestone7:
            80
        case .streakMilestone30:
            300
        case .streakMilestone100:
            1_000
        case .noSpendDay:
            20
        case .budgetRespected:
            50
        case .weeklyChallengeCompleted:
            150
        }
    }

    public var titleKey: String {
        "gamification.reward.\(rawValue).title"
    }

    public var descriptionKey: String {
        "gamification.reward.\(rawValue).description"
    }
}

public struct RewardEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: RewardEventKind
    public let earnedAt: Date
    public let points: Int

    public init(
        id: UUID = UUID(),
        kind: RewardEventKind,
        earnedAt: Date,
        points: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.earnedAt = earnedAt
        self.points = points ?? kind.points
    }
}
