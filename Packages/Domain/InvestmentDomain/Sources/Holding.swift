import Foundation

public struct Holding: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var symbol: String
    public var name: String
    public var assetClass: AssetClass
    public var currency: String
    public var lots: [InvestmentLot]
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        assetClass: AssetClass,
        currency: String = "VND",
        lots: [InvestmentLot] = [],
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.assetClass = assetClass
        self.currency = currency
        self.lots = lots
        self.note = note
        self.createdAt = createdAt
    }

    public var totalQuantity: Decimal {
        lots.reduce(Decimal(0)) { total, lot in
            total + lot.quantity
        }
    }

    public var totalCost: Decimal {
        lots.reduce(Decimal(0)) { total, lot in
            total + lot.totalCost
        }
    }

    public var averageCostPerUnit: Decimal {
        let qty = totalQuantity
        guard qty > 0 else {
            return 0
        }
        return totalCost / qty
    }
}
