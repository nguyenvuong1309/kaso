import BudgetFlowDomain
import Foundation
import Testing

@Test("computes ratios from total and items")
func computesRatios() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 4_000,
        items: [
            ("housing", "category.housing", 1_110, "mint", "house"),
            ("savings", "category.savings", 1_100, "orange", "leaf"),
            ("transport", "category.transport", 475, "blue", "bus"),
            ("food", "category.food", 127, "pink", "fork.knife"),
            ("lifestyle", "category.lifestyle", 12.5, "yellow", "sparkles"),
        ],
        currencyCode: "EUR"
    )

    #expect(flow.nodes.count == 5)
    #expect(flow.nodes.first?.id == "housing")
    #expect(flow.nodes.first?.ratio == 1_110.0 / 4_000.0)
    #expect(flow.currencyCode == "EUR")
}

@Test("drops zero and negative items")
func dropsZeroItems() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 1_000,
        items: [
            ("a", "a", 600, "mint", "circle"),
            ("b", "b", 0, "orange", "circle"),
            ("c", "c", -100, "blue", "circle"),
        ]
    )

    #expect(flow.nodes.count == 1)
    #expect(flow.nodes.first?.id == "a")
}

@Test("when total is zero, falls back to sum of items")
func fallsBackToSum() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 0,
        items: [
            ("a", "a", 200, "mint", "circle"),
            ("b", "b", 300, "orange", "circle"),
        ]
    )

    #expect(flow.total == 500)
    #expect(flow.nodes.first?.ratio == 0.6)
}

@Test("unallocated equals total minus allocated")
func unallocatedRemainder() {
    let flow = BudgetFlowCalculator.makeFlow(
        total: 1_000,
        items: [
            ("a", "a", 700, "mint", "circle"),
        ]
    )

    #expect(flow.unallocated == 300)
}

@Test("empty flow returns no nodes")
func emptyFlow() {
    let flow = BudgetFlowCalculator.makeFlow(total: 0, items: [])
    #expect(flow.nodes.isEmpty)
    #expect(flow.total == 0)
}
