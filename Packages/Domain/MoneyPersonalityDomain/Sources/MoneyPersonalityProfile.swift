import Foundation

public struct MoneyPersonalityTrait: Identifiable, Equatable, Sendable {
    public let id: String
    public let labelKey: String
    public let value: Double  // 0-1

    public init(id: String, labelKey: String, value: Double) {
        self.id = id
        self.labelKey = labelKey
        self.value = max(0, min(1, value))
    }
}

public struct MoneyPersonalityProfile: Equatable, Sendable {
    public let type: MoneyPersonalityType
    public let typeScores: [MoneyPersonalityType: Double]  // 0-1 confidence per type
    public let traits: [MoneyPersonalityTrait]
    public let analyzedTransactionCount: Int
    public let analyzedAt: Date
    public let isSufficient: Bool  // need >= 30 transactions

    public var confidence: Double {
        typeScores[type] ?? 0
    }

    public init(
        type: MoneyPersonalityType,
        typeScores: [MoneyPersonalityType: Double],
        traits: [MoneyPersonalityTrait],
        analyzedTransactionCount: Int,
        analyzedAt: Date,
        isSufficient: Bool
    ) {
        self.type = type
        self.typeScores = typeScores
        self.traits = traits
        self.analyzedTransactionCount = analyzedTransactionCount
        self.analyzedAt = analyzedAt
        self.isSufficient = isSufficient
    }

    public static let insufficientPlaceholder = MoneyPersonalityProfile(
        type: .planner,
        typeScores: [:],
        traits: [],
        analyzedTransactionCount: 0,
        analyzedAt: Date(timeIntervalSinceReferenceDate: 0),
        isSufficient: false
    )
}
