import Foundation

public struct InvestmentLot: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var quantity: Decimal
    public var costBasisPerUnit: Decimal
    public var purchasedAt: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        quantity: Decimal,
        costBasisPerUnit: Decimal,
        purchasedAt: Date,
        note: String? = nil
    ) {
        self.id = id
        self.quantity = quantity
        self.costBasisPerUnit = costBasisPerUnit
        self.purchasedAt = purchasedAt
        self.note = note
    }

    public var totalCost: Decimal {
        quantity * costBasisPerUnit
    }
}
