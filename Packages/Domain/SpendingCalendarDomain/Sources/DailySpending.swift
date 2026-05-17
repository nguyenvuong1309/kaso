import Foundation

public enum DailySpendingKind: String, Codable, Equatable, Sendable {
    case actual
    case forecast
}

public struct DailySpendingItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var label: String
    public var amount: Decimal
    public var category: String?

    public init(id: UUID = UUID(), label: String, amount: Decimal, category: String? = nil) {
        self.id = id
        self.label = label
        self.amount = amount
        self.category = category
    }
}

public struct DailySpending: Identifiable, Equatable, Sendable {
    public var date: Date
    public var total: Decimal
    public var kind: DailySpendingKind
    public var items: [DailySpendingItem]
    public var deltaFromAverage: Double

    public init(
        date: Date,
        total: Decimal,
        kind: DailySpendingKind,
        items: [DailySpendingItem],
        deltaFromAverage: Double
    ) {
        self.date = date
        self.total = total
        self.kind = kind
        self.items = items
        self.deltaFromAverage = deltaFromAverage
    }

    public var id: Date {
        date
    }
}

public enum DailySpendingIntensity: Equatable, Sendable {
    case empty
    case low
    case medium
    case high
}

public extension DailySpending {
    var intensity: DailySpendingIntensity {
        if total <= 0 {
            return .empty
        }
        if deltaFromAverage <= -0.3 {
            return .low
        }
        if deltaFromAverage >= 0.3 {
            return .high
        }
        return .medium
    }
}
