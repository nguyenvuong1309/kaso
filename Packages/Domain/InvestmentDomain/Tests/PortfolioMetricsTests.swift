import Foundation
import Testing
@testable import InvestmentDomain

struct PortfolioMetricsTests {
    private func holding(_ symbol: String) throws -> Holding {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        return Holding(
            symbol: symbol,
            name: symbol,
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 100, purchasedAt: date)]
        )
    }

    private func quote(_ symbol: String) throws -> PriceQuote {
        PriceQuote(symbol: symbol, price: 150, asOf: try makeDate(year: 2025, month: 2, day: 1))
    }

    @Test("empty portfolio metrics constant has zeroed aggregates")
    func emptyConstant() {
        let metrics = PortfolioMetrics.empty
        #expect(metrics.holdingMetrics.isEmpty)
        #expect(metrics.marketValue == 0)
        #expect(metrics.totalCost == 0)
        #expect(metrics.unrealizedPL == 0)
        #expect(metrics.unrealizedPLPercent == 0)
        #expect(metrics.coveredHoldingCount == 0)
        #expect(metrics.totalHoldingCount == 0)
    }

    @Test("hasMissingQuotes is false when coverage equals total count")
    func noMissingQuotes() {
        let metrics = PortfolioMetrics(
            holdingMetrics: [],
            marketValue: 0,
            totalCost: 0,
            unrealizedPL: 0,
            unrealizedPLPercent: 0,
            coveredHoldingCount: 3,
            totalHoldingCount: 3
        )
        #expect(metrics.hasMissingQuotes == false)
    }

    @Test("hasMissingQuotes is true when coverage is below total count")
    func hasMissingQuotes() {
        let metrics = PortfolioMetrics(
            holdingMetrics: [],
            marketValue: 0,
            totalCost: 0,
            unrealizedPL: 0,
            unrealizedPLPercent: 0,
            coveredHoldingCount: 1,
            totalHoldingCount: 3
        )
        #expect(metrics.hasMissingQuotes)
    }

    @Test("holding metrics id mirrors the holding id")
    func holdingMetricsIdentity() throws {
        let holding = try holding("VNM")
        let item = HoldingMetrics(
            holding: holding,
            quote: nil,
            marketValue: 0,
            totalCost: 0,
            unrealizedPL: 0,
            unrealizedPLPercent: 0
        )
        #expect(item.id == holding.id)
    }

    @Test("hasQuote reflects presence of a quote")
    func hasQuoteFlag() throws {
        let withQuote = HoldingMetrics(
            holding: try holding("VNM"),
            quote: try quote("VNM"),
            marketValue: 150,
            totalCost: 100,
            unrealizedPL: 50,
            unrealizedPLPercent: 0.5
        )
        #expect(withQuote.hasQuote)

        let withoutQuote = HoldingMetrics(
            holding: try holding("FPT"),
            quote: nil,
            marketValue: 100,
            totalCost: 100,
            unrealizedPL: 0,
            unrealizedPLPercent: 0
        )
        #expect(withoutQuote.hasQuote == false)
    }

    @Test("holding metrics equatable distinguishes different market values")
    func holdingMetricsEquatable() throws {
        let holding = try holding("VNM")
        let a = HoldingMetrics(holding: holding, quote: nil, marketValue: 100, totalCost: 100, unrealizedPL: 0, unrealizedPLPercent: 0)
        let b = HoldingMetrics(holding: holding, quote: nil, marketValue: 200, totalCost: 100, unrealizedPL: 100, unrealizedPLPercent: 1)
        #expect(a != b)
    }
}
