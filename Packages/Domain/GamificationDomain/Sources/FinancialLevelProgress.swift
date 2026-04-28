import Foundation

public struct FinancialLevelProgress: Equatable, Hashable, Sendable {
    public let level: FinancialLevel
    public let totalPoints: Int

    public init(level: FinancialLevel, totalPoints: Int) {
        self.level = level
        self.totalPoints = max(totalPoints, 0)
    }

    public init(totalPoints: Int) {
        let safe = max(totalPoints, 0)
        self.level = FinancialLevel.level(for: safe)
        self.totalPoints = safe
    }

    public var nextLevel: FinancialLevel? {
        level.nextLevel
    }

    public var pointsInCurrentLevel: Int {
        max(totalPoints - level.minimumPoints, 0)
    }

    public var pointsNeededForNext: Int? {
        guard let next = nextLevel else {
            return nil
        }
        return max(next.minimumPoints - totalPoints, 0)
    }

    public var ratio: Double {
        guard let next = nextLevel else {
            return 1
        }
        let span = Double(next.minimumPoints - level.minimumPoints)
        guard span > 0 else {
            return 1
        }
        return min(max(Double(pointsInCurrentLevel) / span, 0), 1)
    }

    public var isMaxLevel: Bool {
        nextLevel == nil
    }
}
