import Foundation

public struct AllocationSlice: Identifiable, Equatable, Sendable {
    public var assetClass: AssetClass
    public var marketValue: Decimal
    public var fraction: Double

    public init(
        assetClass: AssetClass,
        marketValue: Decimal,
        fraction: Double
    ) {
        self.assetClass = assetClass
        self.marketValue = marketValue
        self.fraction = fraction
    }

    public var id: AssetClass {
        assetClass
    }
}

public struct AllocationBreakdown: Equatable, Sendable {
    public var slices: [AllocationSlice]
    public var marketValue: Decimal

    public init(
        slices: [AllocationSlice],
        marketValue: Decimal
    ) {
        self.slices = slices
        self.marketValue = marketValue
    }

    public static let empty = AllocationBreakdown(slices: [], marketValue: 0)
}

public enum AllocationBreakdownBuilder {
    public static func make(metrics: PortfolioMetrics) -> AllocationBreakdown {
        let totals = metrics.holdingMetrics.reduce(into: [AssetClass: Decimal]()) { partial, item in
            partial[item.holding.assetClass, default: 0] += item.marketValue
        }

        let total = totals.values.reduce(Decimal(0), +)
        let totalDouble = NSDecimalNumber(decimal: total).doubleValue

        let slices = totals
            .map { assetClass, amount -> AllocationSlice in
                let fraction: Double
                if totalDouble > 0 {
                    fraction = NSDecimalNumber(decimal: amount).doubleValue / totalDouble
                } else {
                    fraction = 0
                }
                return AllocationSlice(
                    assetClass: assetClass,
                    marketValue: amount,
                    fraction: fraction
                )
            }
            .sorted { $0.fraction > $1.fraction }

        return AllocationBreakdown(slices: slices, marketValue: total)
    }
}
