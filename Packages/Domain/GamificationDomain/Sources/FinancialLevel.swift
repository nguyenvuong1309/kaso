import Foundation

public enum FinancialLevel: String, CaseIterable, Codable, Equatable, Identifiable, Sendable, Comparable {
    case sprout
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case legend

    public var id: String {
        rawValue
    }

    public var minimumPoints: Int {
        switch self {
        case .sprout:
            0
        case .bronze:
            200
        case .silver:
            800
        case .gold:
            2_000
        case .platinum:
            5_000
        case .diamond:
            10_000
        case .legend:
            25_000
        }
    }

    public var nameKey: String {
        "gamification.financialLevel.\(rawValue)"
    }

    public var descriptionKey: String {
        "gamification.financialLevel.\(rawValue).description"
    }

    public var perkKey: String {
        "gamification.financialLevel.\(rawValue).perk"
    }

    public var symbolName: String {
        switch self {
        case .sprout:
            "leaf.fill"
        case .bronze:
            "circle.hexagongrid.fill"
        case .silver:
            "medal.fill"
        case .gold:
            "trophy.fill"
        case .platinum:
            "crown.fill"
        case .diamond:
            "diamond.fill"
        case .legend:
            "sparkles"
        }
    }

    public static func level(for points: Int) -> FinancialLevel {
        FinancialLevel.allCases
            .filter { $0.minimumPoints <= points }
            .last ?? .sprout
    }

    public var nextLevel: FinancialLevel? {
        let allLevels = FinancialLevel.allCases
        guard let index = allLevels.firstIndex(of: self), index + 1 < allLevels.count else {
            return nil
        }
        return allLevels[index + 1]
    }

    public static func < (lhs: FinancialLevel, rhs: FinancialLevel) -> Bool {
        lhs.minimumPoints < rhs.minimumPoints
    }
}
