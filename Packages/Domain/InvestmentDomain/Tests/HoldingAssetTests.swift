import Foundation
import Testing
@testable import InvestmentDomain
@testable import WealthDomain

struct HoldingAssetTests {
    private func metrics(marketValue: Decimal) -> PortfolioMetrics {
        PortfolioMetrics(
            holdingMetrics: [],
            marketValue: marketValue,
            totalCost: 0,
            unrealizedPL: 0,
            unrealizedPLPercent: 0,
            coveredHoldingCount: 0,
            totalHoldingCount: 0
        )
    }

    @Test("aggregated asset carries id, name and investment type")
    func aggregatedAssetBasics() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AB"))
        let lastUpdatedAt = try makeDate(year: 2025, month: 6, day: 1)
        let asset = metrics(marketValue: 1_500_000).toAggregatedAsset(
            id: id,
            name: "Danh mục đầu tư",
            lastUpdatedAt: lastUpdatedAt
        )
        #expect(asset.id == id)
        #expect(asset.name == "Danh mục đầu tư")
        #expect(asset.type == .investment)
        #expect(asset.isAutoTracked)
        #expect(asset.note == nil)
        #expect(asset.lastUpdatedAt == lastUpdatedAt)
        #expect(decimalsEqual(asset.currentValue, 1_500_000))
    }

    @Test("negative market value is clamped to zero")
    func clampsNegativeValue() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AC"))
        let asset = metrics(marketValue: -500).toAggregatedAsset(
            id: id,
            name: "Portfolio",
            lastUpdatedAt: try makeDate(year: 2025, month: 6, day: 1)
        )
        #expect(asset.currentValue == 0)
    }

    @Test("zero market value maps to zero current value")
    func zeroValue() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AD"))
        let asset = metrics(marketValue: 0).toAggregatedAsset(
            id: id,
            name: "Portfolio",
            lastUpdatedAt: try makeDate(year: 2025, month: 6, day: 1)
        )
        #expect(asset.currentValue == 0)
    }
}
