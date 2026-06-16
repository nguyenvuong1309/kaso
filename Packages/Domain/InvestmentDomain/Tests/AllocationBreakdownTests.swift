import Foundation
import Testing
@testable import InvestmentDomain

struct AllocationBreakdownTests {
    private func metrics(_ holdings: [(AssetClass, Decimal)]) throws -> PortfolioMetrics {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        var holdingMetrics: [HoldingMetrics] = []
        for (index, pair) in holdings.enumerated() {
            let (assetClass, value) = pair
            let holding = Holding(
                symbol: "S\(index)",
                name: "Name \(index)",
                assetClass: assetClass,
                lots: [InvestmentLot(quantity: 1, costBasisPerUnit: value, purchasedAt: date)]
            )
            holdingMetrics.append(
                HoldingMetrics(
                    holding: holding,
                    quote: nil,
                    marketValue: value,
                    totalCost: value,
                    unrealizedPL: 0,
                    unrealizedPLPercent: 0
                )
            )
        }
        let total = holdingMetrics.reduce(Decimal(0)) { $0 + $1.marketValue }
        return PortfolioMetrics(
            holdingMetrics: holdingMetrics,
            marketValue: total,
            totalCost: total,
            unrealizedPL: 0,
            unrealizedPLPercent: 0,
            coveredHoldingCount: 0,
            totalHoldingCount: holdingMetrics.count
        )
    }

    @Test("empty constant has no slices and zero market value")
    func emptyConstant() {
        #expect(AllocationBreakdown.empty.slices.isEmpty)
        #expect(AllocationBreakdown.empty.marketValue == 0)
    }

    @Test("builder returns empty breakdown for empty metrics")
    func builderEmptyMetrics() {
        let breakdown = AllocationBreakdownBuilder.make(metrics: .empty)
        #expect(breakdown.slices.isEmpty)
        #expect(breakdown.marketValue == 0)
    }

    @Test("builder produces a single full-weight slice for one asset class")
    func builderSingleClass() throws {
        let breakdown = AllocationBreakdownBuilder.make(metrics: try metrics([(.stock, 1_000)]))
        #expect(breakdown.slices.count == 1)
        let slice = try #require(breakdown.slices.first)
        #expect(slice.assetClass == .stock)
        #expect(decimalsEqual(slice.marketValue, 1_000))
        #expect(slice.fraction == 1.0)
        #expect(decimalsEqual(breakdown.marketValue, 1_000))
    }

    @Test("builder aggregates holdings of the same asset class")
    func builderAggregatesSameClass() throws {
        let breakdown = AllocationBreakdownBuilder.make(
            metrics: try metrics([(.stock, 600), (.stock, 400)])
        )
        #expect(breakdown.slices.count == 1)
        let slice = try #require(breakdown.slices.first)
        #expect(slice.assetClass == .stock)
        #expect(decimalsEqual(slice.marketValue, 1_000))
        #expect(slice.fraction == 1.0)
    }

    @Test("builder sorts slices by descending fraction")
    func builderSortsDescending() throws {
        let breakdown = AllocationBreakdownBuilder.make(
            metrics: try metrics([(.stock, 250), (.gold, 750)])
        )
        #expect(breakdown.slices.count == 2)
        #expect(breakdown.slices[0].assetClass == .gold)
        #expect(breakdown.slices[0].fraction == 0.75)
        #expect(breakdown.slices[1].assetClass == .stock)
        #expect(breakdown.slices[1].fraction == 0.25)
    }

    @Test("fractions sum to 1 across all slices")
    func fractionsSumToOne() throws {
        let breakdown = AllocationBreakdownBuilder.make(
            metrics: try metrics([(.stock, 200), (.gold, 300), (.bond, 500)])
        )
        let sum = breakdown.slices.reduce(0) { $0 + $1.fraction }
        #expect(abs(sum - 1.0) < 0.0001)
    }

    @Test("zero total market value yields zero fractions without dividing by zero")
    func zeroTotalValue() throws {
        let breakdown = AllocationBreakdownBuilder.make(
            metrics: try metrics([(.stock, 0), (.gold, 0)])
        )
        #expect(breakdown.marketValue == 0)
        #expect(breakdown.slices.allSatisfy { $0.fraction == 0 })
    }

    @Test("allocation slice id mirrors its asset class")
    func sliceIdentity() {
        let slice = AllocationSlice(assetClass: .crypto, marketValue: 10, fraction: 0.5)
        #expect(slice.id == .crypto)
    }

    @Test("allocation slice equatable distinguishes different fractions")
    func sliceEquatable() {
        let a = AllocationSlice(assetClass: .stock, marketValue: 10, fraction: 0.5)
        let b = AllocationSlice(assetClass: .stock, marketValue: 10, fraction: 0.6)
        #expect(a != b)
    }
}
