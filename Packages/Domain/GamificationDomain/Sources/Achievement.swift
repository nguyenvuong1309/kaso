import Foundation

public enum AchievementCategory: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case consistency
    case discipline
    case explorer
    case rewardTier

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "gamification.achievement.category.\(rawValue)"
    }

    public var descriptionKey: String {
        "gamification.achievement.category.\(rawValue).description"
    }
}

public enum AchievementKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case firstSteps
    case weekWarrior
    case monthlyMaster
    case centuryClub
    case noSpendNovice
    case noSpendChampion
    case budgetGuardian
    case categoryCollector
    case dualLogger
    case earlyBird
    case nightOwl
    case rewardCollector
    case eliteCollector

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "gamification.achievement.\(rawValue).title"
    }

    public var descriptionKey: String {
        "gamification.achievement.\(rawValue).description"
    }

    public var category: AchievementCategory {
        switch self {
        case .firstSteps, .weekWarrior, .monthlyMaster, .centuryClub:
            .consistency
        case .noSpendNovice, .noSpendChampion, .budgetGuardian:
            .discipline
        case .categoryCollector, .dualLogger, .earlyBird, .nightOwl:
            .explorer
        case .rewardCollector, .eliteCollector:
            .rewardTier
        }
    }

    public var symbolName: String {
        switch self {
        case .firstSteps:
            "shoeprints.fill"
        case .weekWarrior:
            "flame.fill"
        case .monthlyMaster:
            "moon.stars.fill"
        case .centuryClub:
            "crown.fill"
        case .noSpendNovice:
            "leaf.fill"
        case .noSpendChampion:
            "tree.fill"
        case .budgetGuardian:
            "shield.lefthalf.filled"
        case .categoryCollector:
            "square.grid.2x2.fill"
        case .dualLogger:
            "arrow.triangle.swap"
        case .earlyBird:
            "sunrise.fill"
        case .nightOwl:
            "moon.fill"
        case .rewardCollector:
            "star.fill"
        case .eliteCollector:
            "rosette"
        }
    }

    public var targetValue: Int {
        switch self {
        case .firstSteps:
            1
        case .weekWarrior:
            7
        case .monthlyMaster:
            30
        case .centuryClub:
            100
        case .noSpendNovice:
            3
        case .noSpendChampion:
            10
        case .budgetGuardian:
            5
        case .categoryCollector:
            5
        case .dualLogger:
            1
        case .earlyBird:
            1
        case .nightOwl:
            1
        case .rewardCollector:
            500
        case .eliteCollector:
            2_000
        }
    }
}
