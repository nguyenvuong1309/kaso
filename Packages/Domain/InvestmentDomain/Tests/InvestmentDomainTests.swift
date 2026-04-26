import Foundation
import Testing
@testable import InvestmentDomain
@testable import WealthDomain

@Test("portfolio metrics aggregate market value, cost and PL with full quotes")
func portfolioMetricsWithQuotes() throws {
    let purchaseDate = try fixedDate(year: 2025, month: 6, day: 1)
    let holdings = [
        Holding(
            symbol: "VNM",
            name: "Vinamilk",
            assetClass: .stock,
            lots: [
                InvestmentLot(quantity: 100, costBasisPerUnit: 70_000, purchasedAt: purchaseDate),
            ]
        ),
        Holding(
            symbol: "FPT",
            name: "FPT Corp",
            assetClass: .stock,
            lots: [
                InvestmentLot(quantity: 50, costBasisPerUnit: 90_000, purchasedAt: purchaseDate),
                InvestmentLot(quantity: 50, costBasisPerUnit: 100_000, purchasedAt: purchaseDate),
            ]
        ),
    ]
    let quotes = [
        PriceQuote(symbol: "VNM", price: 75_000, asOf: Date()),
        PriceQuote(symbol: "FPT", price: 110_000, asOf: Date()),
    ]

    let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)

    #expect(metrics.holdingMetrics.count == 2)
    #expect(metrics.coveredHoldingCount == 2)
    #expect(metrics.marketValue == 100 * 75_000 + 100 * 110_000)
    #expect(metrics.totalCost == 100 * 70_000 + 50 * 90_000 + 50 * 100_000)
    #expect(metrics.unrealizedPL == metrics.marketValue - metrics.totalCost)
    #expect(metrics.unrealizedPLPercent > 0)
    #expect(metrics.hasMissingQuotes == false)
}

@Test("missing quotes fall back to cost-basis market value")
func missingQuotesFallback() throws {
    let purchaseDate = try fixedDate(year: 2025, month: 6, day: 1)
    let holdings = [
        Holding(
            symbol: "ABC",
            name: "ABC Corp",
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 10, costBasisPerUnit: 50_000, purchasedAt: purchaseDate)]
        ),
    ]
    let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: [])

    #expect(metrics.coveredHoldingCount == 0)
    #expect(metrics.marketValue == 500_000)
    #expect(metrics.totalCost == 500_000)
    #expect(metrics.unrealizedPL == 0)
    #expect(metrics.hasMissingQuotes)
}

@Test("allocation breakdown groups by asset class with descending fraction")
func allocationBreakdownGroups() throws {
    let purchaseDate = try fixedDate(year: 2025, month: 1, day: 1)
    let holdings = [
        Holding(
            symbol: "S1",
            name: "Stock 1",
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 100, purchasedAt: purchaseDate)]
        ),
        Holding(
            symbol: "G1",
            name: "Gold",
            assetClass: .gold,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 300, purchasedAt: purchaseDate)]
        ),
    ]
    let quotes = [
        PriceQuote(symbol: "S1", price: 100, asOf: Date()),
        PriceQuote(symbol: "G1", price: 300, asOf: Date()),
    ]
    let metrics = PortfolioMetricsCalculator.calculate(holdings: holdings, quotes: quotes)

    let breakdown = AllocationBreakdownBuilder.make(metrics: metrics)

    #expect(breakdown.slices.count == 2)
    #expect(breakdown.slices[0].assetClass == .gold)
    #expect(breakdown.slices[0].fraction == 0.75)
    #expect(breakdown.slices[1].assetClass == .stock)
    #expect(breakdown.slices[1].fraction == 0.25)
}

@Test("rebalance engine returns empty when target is empty")
func rebalanceEmptyTarget() throws {
    let breakdown = AllocationBreakdown(
        slices: [AllocationSlice(assetClass: .stock, marketValue: 100, fraction: 1.0)],
        marketValue: 100
    )
    let suggestion = RebalanceEngine.suggest(breakdown: breakdown, target: .empty)

    #expect(suggestion.actions.isEmpty)
    #expect(suggestion.driftScore == 0)
}

@Test("rebalance engine produces buy and sell actions when drift exceeds tolerance")
func rebalanceBuyAndSell() throws {
    let breakdown = AllocationBreakdown(
        slices: [
            AllocationSlice(assetClass: .stock, marketValue: 800_000, fraction: 0.8),
            AllocationSlice(assetClass: .gold, marketValue: 200_000, fraction: 0.2),
        ],
        marketValue: 1_000_000
    )
    let target = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])

    let suggestion = RebalanceEngine.suggest(breakdown: breakdown, target: target)

    #expect(suggestion.actions.count == 2)
    #expect(suggestion.isSignificant)
    let stockAction = try #require(suggestion.actions.first { $0.assetClass == .stock })
    #expect(stockAction.kind == .sell)
    let goldAction = try #require(suggestion.actions.first { $0.assetClass == .gold })
    #expect(goldAction.kind == .buy)
}

@Test("target allocation rejects fractions not summing to 1")
func targetAllocationValidates() {
    let invalid = TargetAllocation(fractions: [.stock: 0.5, .gold: 0.4])
    #expect(invalid.validationErrors().contains(.sumMustEqual100Percent))

    let negative = TargetAllocation(fractions: [.stock: 1.1, .gold: -0.1])
    #expect(negative.validationErrors().contains(.fractionMustBeNonNegative))

    let valid = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
    #expect(valid.isValid)
}

@Test("holding draft validates symbol, name and lot constraints")
func holdingDraftValidation() throws {
    let invalid = HoldingDraft(
        symbol: "  ",
        name: "  ",
        lots: [
            LotDraft(quantity: 0, costBasisPerUnit: -1, purchasedAt: Date()),
        ]
    )

    #expect(
        Set(invalid.validationErrors()) == Set([
            .symbolRequired,
            .nameRequired,
            .lotQuantityMustBePositive,
            .lotCostBasisCannotBeNegative,
        ])
    )

    let valid = HoldingDraft(
        symbol: " vnm ",
        name: "Vinamilk",
        assetClass: .stock,
        lots: [LotDraft(quantity: 100, costBasisPerUnit: 70_000, purchasedAt: Date())]
    )

    let holding = try valid.validated()
    #expect(holding.symbol == "VNM")
}

@Test("portfolio metrics convert to aggregated investment asset")
func portfolioToAsset() throws {
    let holding = Holding(
        symbol: "VNM",
        name: "Vinamilk",
        assetClass: .stock,
        lots: [InvestmentLot(quantity: 10, costBasisPerUnit: 70_000, purchasedAt: Date())]
    )
    let quote = PriceQuote(symbol: "VNM", price: 80_000, asOf: Date())
    let metrics = PortfolioMetricsCalculator.calculate(holdings: [holding], quotes: [quote])
    let assetID = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA"))

    let asset = metrics.toAggregatedAsset(id: assetID, name: "Danh mục đầu tư")

    #expect(asset.id == assetID)
    #expect(asset.type == .investment)
    #expect(asset.currentValue == 800_000)
    #expect(asset.isAutoTracked)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func fixedDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
