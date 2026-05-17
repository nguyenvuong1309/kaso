import Foundation

public struct RoundUpEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var sourceTransactionID: UUID?
    public var originalAmount: Decimal
    public var roundedAmount: Decimal
    public var contribution: Decimal
    public var step: RoundUpStep
    public var savingGoalID: UUID?
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sourceTransactionID: UUID? = nil,
        originalAmount: Decimal,
        roundedAmount: Decimal,
        contribution: Decimal,
        step: RoundUpStep,
        savingGoalID: UUID? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sourceTransactionID = sourceTransactionID
        self.originalAmount = originalAmount
        self.roundedAmount = roundedAmount
        self.contribution = contribution
        self.step = step
        self.savingGoalID = savingGoalID
        self.note = note
        self.createdAt = createdAt
    }
}
