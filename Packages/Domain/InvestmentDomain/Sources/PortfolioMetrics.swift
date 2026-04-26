import Foundation

public struct HoldingMetrics: Identifiable, Equatable, Sendable {
    public var holding: Holding
    public var quote: PriceQuote?
    public var marketValue: Decimal
    public var totalCost: Decimal
    public var unrealizedPL: Decimal
    public var unrealizedPLPercent: Double

    public init(
        holding: Holding,
        quote: PriceQuote?,
        marketValue: Decimal,
        totalCost: Decimal,
        unrealizedPL: Decimal,
        unrealizedPLPercent: Double
    ) {
        self.holding = holding
        self.quote = quote
        self.marketValue = marketValue
        self.totalCost = totalCost
        self.unrealizedPL = unrealizedPL
        self.unrealizedPLPercent = unrealizedPLPercent
    }

    public var id: UUID {
        holding.id
    }

    public var hasQuote: Bool {
        quote != nil
    }
}

public struct PortfolioMetrics: Equatable, Sendable {
    public var holdingMetrics: [HoldingMetrics]
    public var marketValue: Decimal
    public var totalCost: Decimal
    public var unrealizedPL: Decimal
    public var unrealizedPLPercent: Double
    public var coveredHoldingCount: Int
    public var totalHoldingCount: Int

    public init(
        holdingMetrics: [HoldingMetrics],
        marketValue: Decimal,
        totalCost: Decimal,
        unrealizedPL: Decimal,
        unrealizedPLPercent: Double,
        coveredHoldingCount: Int,
        totalHoldingCount: Int
    ) {
        self.holdingMetrics = holdingMetrics
        self.marketValue = marketValue
        self.totalCost = totalCost
        self.unrealizedPL = unrealizedPL
        self.unrealizedPLPercent = unrealizedPLPercent
        self.coveredHoldingCount = coveredHoldingCount
        self.totalHoldingCount = totalHoldingCount
    }

    public static let empty = PortfolioMetrics(
        holdingMetrics: [],
        marketValue: 0,
        totalCost: 0,
        unrealizedPL: 0,
        unrealizedPLPercent: 0,
        coveredHoldingCount: 0,
        totalHoldingCount: 0
    )

    public var hasMissingQuotes: Bool {
        coveredHoldingCount < totalHoldingCount
    }
}
