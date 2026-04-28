import Foundation

public enum WeeklyChallengeKind: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case dailyStreak
    case noSpendDays
    case budgetKeeper
    case categoryVariety
    case incomeLogger

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "gamification.weeklyChallenge.\(rawValue).title"
    }

    public var descriptionKey: String {
        "gamification.weeklyChallenge.\(rawValue).description"
    }

    public var symbolName: String {
        switch self {
        case .dailyStreak:
            "calendar.badge.checkmark"
        case .noSpendDays:
            "leaf.arrow.circlepath"
        case .budgetKeeper:
            "shield.checkered"
        case .categoryVariety:
            "rectangle.3.group.fill"
        case .incomeLogger:
            "banknote.fill"
        }
    }

    public var defaultTarget: Int {
        switch self {
        case .dailyStreak:
            7
        case .noSpendDays:
            3
        case .budgetKeeper:
            5
        case .categoryVariety:
            4
        case .incomeLogger:
            1
        }
    }

    public var rewardPoints: Int {
        switch self {
        case .dailyStreak:
            200
        case .noSpendDays:
            150
        case .budgetKeeper:
            200
        case .categoryVariety:
            100
        case .incomeLogger:
            80
        }
    }
}

public struct WeeklyChallenge: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WeeklyChallengeKind
    public let weekStart: Date
    public let target: Int
    public var currentProgress: Int
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        kind: WeeklyChallengeKind,
        weekStart: Date,
        target: Int? = nil,
        currentProgress: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.kind = kind
        self.weekStart = weekStart
        self.target = target ?? kind.defaultTarget
        self.currentProgress = max(currentProgress, 0)
        self.completedAt = completedAt
    }

    public var isCompleted: Bool {
        completedAt != nil
    }

    public var ratio: Double {
        guard target > 0 else {
            return 0
        }
        return min(Double(currentProgress) / Double(target), 1)
    }

    public var displayProgress: Int {
        min(currentProgress, target)
    }

    public func weekEnd(calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    public func daysRemaining(referenceDate: Date, calendar: Calendar = .current) -> Int {
        let end = weekEnd(calendar: calendar)
        let referenceDay = calendar.startOfDay(for: referenceDate)
        let endDay = calendar.startOfDay(for: end)
        let components = calendar.dateComponents([.day], from: referenceDay, to: endDay)
        return max(components.day ?? 0, 0)
    }
}
