import Foundation

public struct AchievementProgress: Equatable, Hashable, Sendable, Identifiable {
    public let kind: AchievementKind
    public let currentValue: Int
    public let isUnlocked: Bool

    public init(
        kind: AchievementKind,
        currentValue: Int,
        isUnlocked: Bool
    ) {
        self.kind = kind
        self.currentValue = max(currentValue, 0)
        self.isUnlocked = isUnlocked
    }

    public var id: String {
        kind.id
    }

    public var targetValue: Int {
        kind.targetValue
    }

    public var ratio: Double {
        guard targetValue > 0 else {
            return 0
        }
        return min(Double(currentValue) / Double(targetValue), 1)
    }

    public var displayValue: Int {
        min(currentValue, targetValue)
    }
}
