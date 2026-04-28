import Foundation

public enum StreakLevel: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case newcomer
    case consistent
    case disciplined
    case master
    case legendary

    public var id: String {
        rawValue
    }

    public var minStreakDays: Int {
        switch self {
        case .newcomer:
            0
        case .consistent:
            3
        case .disciplined:
            7
        case .master:
            30
        case .legendary:
            100
        }
    }

    public var nameKey: String {
        "gamification.level.\(rawValue)"
    }

    public var descriptionKey: String {
        "gamification.level.\(rawValue).description"
    }

    public static func level(for streakDays: Int) -> StreakLevel {
        StreakLevel.allCases
            .filter { $0.minStreakDays <= streakDays }
            .last ?? .newcomer
    }

    public var nextLevel: StreakLevel? {
        let allLevels = StreakLevel.allCases
        guard let index = allLevels.firstIndex(of: self), index + 1 < allLevels.count else {
            return nil
        }
        return allLevels[index + 1]
    }
}
