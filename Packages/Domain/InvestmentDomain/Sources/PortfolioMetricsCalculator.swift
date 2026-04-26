import Foundation

public enum PortfolioMetricsCalculator {
    public static func calculate(
        holdings: [Holding],
        quotes: [PriceQuote]
    ) -> PortfolioMetrics {
        let quoteMap = Dictionary(uniqueKeysWithValues: quotes.map { ($0.symbol.uppercased(), $0) })

        var holdingMetrics: [HoldingMetrics] = []
        holdingMetrics.reserveCapacity(holdings.count)
        var marketValue: Decimal = 0
        var totalCost: Decimal = 0
        var coveredCount = 0

        for holding in holdings {
            let key = holding.symbol.uppercased()
            let quote = quoteMap[key]
            let cost = holding.totalCost
            let value: Decimal
            if let quote {
                value = holding.totalQuantity * quote.price
                coveredCount += 1
            } else {
                value = cost
            }

            let pl = value - cost
            let plPercent: Double
            if cost > 0 {
                plPercent = NSDecimalNumber(decimal: pl).doubleValue
                    / NSDecimalNumber(decimal: cost).doubleValue
            } else {
                plPercent = 0
            }

            holdingMetrics.append(
                HoldingMetrics(
                    holding: holding,
                    quote: quote,
                    marketValue: value,
                    totalCost: cost,
                    unrealizedPL: pl,
                    unrealizedPLPercent: plPercent
                )
            )

            marketValue += value
            totalCost += cost
        }

        let totalPL = marketValue - totalCost
        let totalPercent: Double
        if totalCost > 0 {
            totalPercent = NSDecimalNumber(decimal: totalPL).doubleValue
                / NSDecimalNumber(decimal: totalCost).doubleValue
        } else {
            totalPercent = 0
        }

        return PortfolioMetrics(
            holdingMetrics: holdingMetrics.sorted { $0.marketValue > $1.marketValue },
            marketValue: marketValue,
            totalCost: totalCost,
            unrealizedPL: totalPL,
            unrealizedPLPercent: totalPercent,
            coveredHoldingCount: coveredCount,
            totalHoldingCount: holdings.count
        )
    }
}
