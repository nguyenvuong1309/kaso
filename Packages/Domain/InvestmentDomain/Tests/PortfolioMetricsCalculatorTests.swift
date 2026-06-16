import Foundation
import Testing
@testable import InvestmentDomain

struct PortfolioMetricsCalculatorTests {
    private func holding(
        _ symbol: String,
        assetClass: AssetClass = .stock,
        quantity: Decimal,
        cost: Decimal
    ) throws -> Holding {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        return Holding(
            symbol: symbol,
            name: symbol,
            assetClass: assetClass,
            lots: [InvestmentLot(quantity: quantity, costBasisPerUnit: cost, purchasedAt: date)]
        )
    }

    private func quote(_ symbol: String, _ price: Decimal) throws -> PriceQuote {
        PriceQuote(symbol: symbol, price: price, asOf: try makeDate(year: 2025, month: 2, day: 1))
    }

    @Test("empty holdings produce the zeroed metrics")
    func emptyHoldings() {
        let metrics = PortfolioMetricsCalculator.calculate(holdings: [], quotes: [])
        #expect(metrics.holdingMetrics.isEmpty)
        #expect(metrics.marketValue == 0)
        #expect(metrics.totalCost == 0)
        #expect(metrics.unrealizedPL == 0)
        #expect(metrics.unrealizedPLPercent == 0)
        #expect(metrics.coveredHoldingCount == 0)
        #expect(metrics.totalHoldingCount == 0)
    }

    @Test("holding metrics are sorted by descending market value")
    func sortedByMarketValue() throws {
        let holdings = [
            try holding("SMALL", quantity: 1, cost: 100),
            try holding("BIG", quantity: 10, cost: 100),
        ]
        let quotes = [
            try quote("SMALL", 100),
            try quote("BIG", 100),
        ]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        #expect(metrics.holdingMetrics.first?.holding.symbol == "BIG")
        #expect(metrics.holdingMetrics.last?.holding.symbol == "SMALL")
    }

    @Test("quote matching is case-insensitive")
    func caseInsensitiveQuoteMatch() throws {
        let holdings = [try holding("vnm", quantity: 2, cost: 100)]
        let quotes = [try quote("VNM", 200)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        #expect(metrics.coveredHoldingCount == 1)
        #expect(decimalsEqual(metrics.marketValue, 400))
    }

    @Test("partial coverage reports correct covered count")
    func partialCoverage() throws {
        let holdings = [
            try holding("A", quantity: 1, cost: 100),
            try holding("B", quantity: 1, cost: 100),
        ]
        let quotes = [try quote("A", 150)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        #expect(metrics.coveredHoldingCount == 1)
        #expect(metrics.totalHoldingCount == 2)
        #expect(metrics.hasMissingQuotes)
        // A covered: 150, B falls back to cost 100
        #expect(decimalsEqual(metrics.marketValue, 250))
    }

    @Test("per-holding PL percent divides PL by cost")
    func plPercentForHolding() throws {
        let holdings = [try holding("A", quantity: 1, cost: 100)]
        let quotes = [try quote("A", 150)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        let item = try #require(metrics.holdingMetrics.first)
        #expect(decimalsEqual(item.unrealizedPL, 50))
        #expect(abs(item.unrealizedPLPercent - 0.5) < 0.0001)
    }

    @Test("zero-cost holding yields zero PL percent without dividing by zero")
    func zeroCostHolding() throws {
        let holdings = [try holding("FREE", quantity: 10, cost: 0)]
        let quotes = [try quote("FREE", 100)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        let item = try #require(metrics.holdingMetrics.first)
        #expect(item.totalCost == 0)
        #expect(item.unrealizedPLPercent == 0)
        #expect(metrics.unrealizedPLPercent == 0)
        #expect(decimalsEqual(item.marketValue, 1_000))
    }

    @Test("negative PL is computed when price drops below cost")
    func negativePL() throws {
        let holdings = [try holding("DOWN", quantity: 1, cost: 200)]
        let quotes = [try quote("DOWN", 150)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)
        #expect(decimalsEqual(metrics.unrealizedPL, -50))
        #expect(metrics.unrealizedPLPercent < 0)
    }

    @Test("holding without quote keeps its quote nil and falls back to cost")
    func uncoveredHoldingMetrics() throws {
        let holdings = [try holding("NOQ", quantity: 4, cost: 100)]
        let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: [])
        let item = try #require(metrics.holdingMetrics.first)
        #expect(item.quote == nil)
        #expect(item.hasQuote == false)
        #expect(decimalsEqual(item.marketValue, item.totalCost))
        #expect(decimalsEqual(item.marketValue, 400))
    }
}
