import Foundation

public enum PurchasePlanCategory: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case fashion
    case electronics
    case home
    case travel
    case entertainment
    case foodDrink
    case beauty
    case hobby
    case other

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "coolingOff.category.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .fashion:
            "tshirt"
        case .electronics:
            "iphone"
        case .home:
            "house"
        case .travel:
            "airplane"
        case .entertainment:
            "gamecontroller"
        case .foodDrink:
            "cup.and.saucer"
        case .beauty:
            "sparkles"
        case .hobby:
            "paintbrush"
        case .other:
            "ellipsis.circle"
        }
    }
}

public enum PurchasePlanStatus: String, CaseIterable, Codable, Equatable, Sendable {
    case waiting
    case approved
    case cancelled
    case expired
}

public struct PurchasePlan: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var amount: Decimal
    public var category: PurchasePlanCategory
    public var note: String?
    public var coolingPeriod: CoolingPeriod
    public var status: PurchasePlanStatus
    public var createdAt: Date
    public var availableAt: Date
    public var decisionAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        category: PurchasePlanCategory = .other,
        note: String? = nil,
        coolingPeriod: CoolingPeriod = .threeDays,
        status: PurchasePlanStatus = .waiting,
        createdAt: Date = Date(),
        availableAt: Date,
        decisionAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.note = note
        self.coolingPeriod = coolingPeriod
        self.status = status
        self.createdAt = createdAt
        self.availableAt = availableAt
        self.decisionAt = decisionAt
    }

    public func remainingSeconds(asOf now: Date) -> TimeInterval {
        max(availableAt.timeIntervalSince(now), 0)
    }

    public func isReady(asOf now: Date) -> Bool {
        availableAt <= now
    }
}
