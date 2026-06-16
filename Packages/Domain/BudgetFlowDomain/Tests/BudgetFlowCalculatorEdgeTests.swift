import Foundation
import Testing
@testable import BudgetFlowDomain

@Test("nodes are sorted by descending amount regardless of input order")
func sortsByDescendingAmount() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 1_000,
        items: [
            ("small", "small", 100, "mint", "circle"),
            ("big", "big", 600, "orange", "circle"),
            ("mid", "mid", 300, "blue", "circle"),
        ]
    )

    #expect(flow.nodes.map(\.id) == ["big", "mid", "small"])
}

@Test("negative total is sanitized then falls back to sum of items")
func negativeTotalFallsBackToSum() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: -500,
        items: [
            ("a", "a", 200, "mint", "circle"),
            ("b", "b", 300, "orange", "circle"),
        ]
    )

    #expect(flow.total == 500)
    #expect(flow.nodes.first?.id == "b")
    #expect(flow.nodes.first?.ratio == 0.6)
}

@Test("default currency code is VND")
func defaultCurrencyCode() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 100,
        items: [("a", "a", 100, "mint", "circle")]
    )

    #expect(flow.currencyCode == "VND")
}

@Test("ratios are computed against the provided total even when items underflow it")
func ratiosUseProvidedTotal() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 1_000,
        items: [
            ("a", "a", 250, "mint", "circle"),
            ("b", "b", 250, "orange", "circle"),
        ]
    )

    #expect(flow.total == 1_000)
    #expect(flow.nodes.allSatisfy { $0.ratio == 0.25 })
    #expect(flow.unallocated == 500)
}

@Test("total is widened to item sum when items exceed the provided total")
func totalWidensToItemSumWhenOverAllocated() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 1_000,
        items: [
            ("a", "a", 800, "mint", "circle"),
            ("b", "b", 700, "orange", "circle"),
        ]
    )

    // total stays at the provided value because it is the larger of the two.
    #expect(flow.total == 1_000)
    // ratios still divide by the provided total, so they can exceed 1.
    #expect(flow.nodes.first?.ratio == 0.8)
}

@Test("all-zero items with zero total produce no nodes and zero total")
func allZeroItemsZeroTotal() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 0,
        items: [
            ("a", "a", 0, "mint", "circle"),
            ("b", "b", 0, "orange", "circle"),
        ]
    )

    #expect(flow.nodes.isEmpty)
    #expect(flow.total == 0)
}

@Test("single item with zero total yields a ratio of one")
func singleItemZeroTotalRatioOne() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 0,
        items: [("a", "a", 750, "mint", "circle")]
    )

    #expect(flow.total == 750)
    #expect(flow.nodes.first?.ratio == 1.0)
}

@Test("node preserves label, color and symbol metadata")
func preservesNodeMetadata() throws {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 100,
        items: [("savings", "category.savings", 100, "orange", "leaf")]
    )

    let node = try #require(flow.nodes.first)
    #expect(node.labelKey == "category.savings")
    #expect(node.colorName == "orange")
    #expect(node.symbolName == "leaf")
    #expect(node.amount == 100)
}

@Test("ratios across all items sum to one when total equals item sum")
func ratiosSumToOne() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 0,
        items: [
            ("a", "a", 100, "mint", "circle"),
            ("b", "b", 300, "orange", "circle"),
            ("c", "c", 100, "blue", "circle"),
        ]
    )

    let sum = flow.nodes.reduce(0.0) { $0 + $1.ratio }
    #expect(abs(sum - 1.0) < 0.0000001)
}
