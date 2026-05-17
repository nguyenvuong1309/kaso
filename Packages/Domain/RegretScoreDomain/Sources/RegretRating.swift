import Foundation

public enum RegretScore: Int, CaseIterable, Codable, Equatable, Sendable {
    case noRegret = 1
    case slight = 2
    case neutral = 3
    case regret = 4
    case strongRegret = 5

    public var nameKey: String {
        "regret.score.\(rawValue)"
    }

    public var symbolName: String {
        switch self {
        case .noRegret:
            "hand.thumbsup.fill"
        case .slight:
            "hand.thumbsup"
        case .neutral:
            "minus.circle"
        case .regret:
            "hand.thumbsdown"
        case .strongRegret:
            "hand.thumbsdown.fill"
        }
    }

    public var isRegret: Bool {
        self == .regret || self == .strongRegret
    }
}

public struct RegretRating: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var purchaseTitle: String
    public var category: String
    public var amount: Decimal
    public var score: RegretScore
    public var note: String?
    public var purchasedAt: Date
    public var ratedAt: Date

    public init(
        id: UUID = UUID(),
        purchaseTitle: String,
        category: String,
        amount: Decimal,
        score: RegretScore,
        note: String? = nil,
        purchasedAt: Date,
        ratedAt: Date = Date()
    ) {
        self.id = id
        self.purchaseTitle = purchaseTitle
        self.category = category
        self.amount = amount
        self.score = score
        self.note = note
        self.purchasedAt = purchasedAt
        self.ratedAt = ratedAt
    }
}
