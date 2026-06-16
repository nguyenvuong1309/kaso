import Foundation
import Testing
@testable import InvestmentDomain

struct RebalanceEngineTests {
    private func breakdown(_ slices: [(AssetClass, Double)], total: Decimal) -> AllocationBreakdown {
        let allocationSlices = slices.map { assetClass, fraction in
            AllocationSlice(
                assetClass: assetClass,
                marketValue: Decimal(fraction) * total,
                fraction: fraction
            )
        }
        return AllocationBreakdown(slices: allocationSlices, marketValue: total)
    }

    @Test("empty suggestion constant has no actions and zero drift")
    func emptyConstant() {
        #expect(RebalanceSuggestion.empty.actions.isEmpty)
        #expect(RebalanceSuggestion.empty.driftScore == 0)
        #expect(RebalanceSuggestion.empty.isSignificant == false)
    }

    @Test("returns empty when target fractions are empty")
    func emptyTarget() {
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 1.0)], total: 1_000),
            target: .empty
        )
        #expect(result == .empty)
    }

    @Test("returns empty when breakdown has no market value")
    func zeroMarketValue() {
        let result = RebalanceEngine.suggest(
            breakdown: AllocationBreakdown(slices: [], marketValue: 0),
            target: TargetAllocation(fractions: [.stock: 1.0])
        )
        #expect(result == .empty)
    }

    @Test("perfectly aligned portfolio produces no actions and zero drift")
    func alignedPortfolio() {
        let target = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 0.6), (.gold, 0.4)], total: 1_000_000),
            target: target
        )
        #expect(result.actions.isEmpty)
        #expect(result.driftScore < 0.0001)
    }

    @Test("drift below tolerance is skipped but still counts toward drift score")
    func toleranceSkip() {
        // 0.4% drift each side — below 0.5% tolerance, so no actions.
        let target = TargetAllocation(fractions: [.stock: 0.604, .gold: 0.396])
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 0.6), (.gold, 0.4)], total: 1_000_000),
            target: target
        )
        #expect(result.actions.isEmpty)
        #expect(result.driftScore > 0)
    }

    @Test("buy and sell actions are emitted and sorted by descending drift")
    func buyAndSellSorted() throws {
        let target = TargetAllocation(fractions: [.stock: 0.5, .gold: 0.3, .bond: 0.2])
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 0.8), (.gold, 0.2)], total: 1_000_000),
            target: target
        )
        // stock: over (sell), gold: under (buy), bond: missing -> under (buy)
        #expect(result.actions.count == 3)
        let stock = try #require(result.actions.first { $0.assetClass == .stock })
        #expect(stock.kind == .sell)
        let gold = try #require(result.actions.first { $0.assetClass == .gold })
        #expect(gold.kind == .buy)
        let bond = try #require(result.actions.first { $0.assetClass == .bond })
        #expect(bond.kind == .buy)

        // sorted by descending |drift|: stock drift 0.3 should be first.
        #expect(result.actions.first?.assetClass == .stock)
        let drifts = result.actions.map { abs($0.driftFraction) }
        #expect(drifts == drifts.sorted(by: >))
    }

    @Test("action amount approximates the value to move")
    func actionAmount() throws {
        let target = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 0.8), (.gold, 0.2)], total: 1_000_000),
            target: target
        )
        let stock = try #require(result.actions.first { $0.assetClass == .stock })
        // |0.6 - 0.8| * 1_000_000 = 200_000
        let amount = NSDecimalNumber(decimal: stock.amount).doubleValue
        #expect(abs(amount - 200_000) < 1.0)
    }

    @Test("drift score is half the total absolute drift")
    func driftScoreHalving() {
        let target = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        let result = RebalanceEngine.suggest(
            breakdown: breakdown([(.stock, 0.8), (.gold, 0.2)], total: 1_000_000),
            target: target
        )
        // |0.6-0.8| + |0.4-0.2| = 0.4 total; /2 = 0.2
        #expect(abs(result.driftScore - 0.2) < 0.0001)
    }

    @Test("isSignificant boundary at 5 percent drift score")
    func isSignificantBoundary() {
        let below = RebalanceSuggestion(actions: [], driftScore: 0.049)
        #expect(below.isSignificant == false)
        let atThreshold = RebalanceSuggestion(actions: [], driftScore: 0.05)
        #expect(atThreshold.isSignificant)
    }

    @Test("rebalance action drift fraction is current minus target")
    func actionDriftFraction() {
        let action = RebalanceAction(
            assetClass: .stock,
            kind: .sell,
            amount: 100,
            currentFraction: 0.8,
            targetFraction: 0.5
        )
        #expect(abs(action.driftFraction - 0.3) < 0.0001)
        #expect(action.id == .stock)
    }

    @Test("rebalance action kind raw values are stable")
    func actionKindRawValues() {
        #expect(RebalanceActionKind.buy.rawValue == "buy")
        #expect(RebalanceActionKind.sell.rawValue == "sell")
    }
}
