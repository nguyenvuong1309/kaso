import Foundation
import Testing
@testable import BudgetFlowDomain

// MARK: - BudgetFlowNode

@Test("node stores all properties from initializer")
func nodeInitializerStoresProperties() {
    let node = BudgetFlowNode(
        id: "housing",
        labelKey: "category.housing",
        amount: 1_500_000,
        ratio: 0.5,
        colorName: "mint",
        symbolName: "house"
    )

    #expect(node.id == "housing")
    #expect(node.labelKey == "category.housing")
    #expect(node.amount == 1_500_000)
    #expect(node.ratio == 0.5)
    #expect(node.colorName == "mint")
    #expect(node.symbolName == "house")
}

@Test("nodes with identical values are equal")
func nodeEquatableEqual() {
    let lhs = BudgetFlowNode(
        id: "a",
        labelKey: "a",
        amount: 100,
        ratio: 0.25,
        colorName: "blue",
        symbolName: "circle"
    )
    let rhs = BudgetFlowNode(
        id: "a",
        labelKey: "a",
        amount: 100,
        ratio: 0.25,
        colorName: "blue",
        symbolName: "circle"
    )

    #expect(lhs == rhs)
}

@Test("nodes differing in any property are not equal")
func nodeEquatableNotEqual() {
    let base = BudgetFlowNode(
        id: "a",
        labelKey: "a",
        amount: 100,
        ratio: 0.25,
        colorName: "blue",
        symbolName: "circle"
    )

    var differentAmount = base
    differentAmount.amount = 200
    #expect(base != differentAmount)

    var differentRatio = base
    differentRatio.ratio = 0.5
    #expect(base != differentRatio)

    var differentLabel = base
    differentLabel.labelKey = "b"
    #expect(base != differentLabel)
}

// MARK: - BudgetFlow defaults & init

@Test("default initializer uses VND and empty nodes")
func budgetFlowDefaultInit() {
    let flow = BudgetFlow()

    #expect(flow.total == 0)
    #expect(flow.nodes.isEmpty)
    #expect(flow.currencyCode == "VND")
}

@Test("custom initializer stores provided values")
func budgetFlowCustomInit() {
    let node = BudgetFlowNode(
        id: "x",
        labelKey: "x",
        amount: 500,
        ratio: 0.5,
        colorName: "orange",
        symbolName: "leaf"
    )
    let flow = BudgetFlow(total: 1_000, nodes: [node], currencyCode: "USD")

    #expect(flow.total == 1_000)
    #expect(flow.nodes == [node])
    #expect(flow.currencyCode == "USD")
}

@Test("empty static value equals a default-initialized flow")
func budgetFlowEmptyStatic() {
    #expect(BudgetFlow.empty == BudgetFlow())
    #expect(BudgetFlow.empty.nodes.isEmpty)
    #expect(BudgetFlow.empty.total == 0)
    #expect(BudgetFlow.empty.currencyCode == "VND")
}

// MARK: - allocatedTotal

@Test("allocatedTotal sums every node amount")
func allocatedTotalSumsNodes() {
    let flow = BudgetFlow(
        total: 1_000,
        nodes: [
            makeNode(id: "a", amount: 300),
            makeNode(id: "b", amount: 250),
            makeNode(id: "c", amount: 50),
        ]
    )

    #expect(flow.allocatedTotal == 600)
}

@Test("allocatedTotal is zero when there are no nodes")
func allocatedTotalEmpty() {
    let flow = BudgetFlow(total: 1_000)
    #expect(flow.allocatedTotal == 0)
}

// MARK: - unallocated

@Test("unallocated is total minus allocated when positive")
func unallocatedPositive() {
    let flow = BudgetFlow(
        total: 1_000,
        nodes: [makeNode(id: "a", amount: 400)]
    )

    #expect(flow.unallocated == 600)
}

@Test("unallocated is clamped to zero when over-allocated")
func unallocatedClampedToZero() {
    let flow = BudgetFlow(
        total: 1_000,
        nodes: [
            makeNode(id: "a", amount: 800),
            makeNode(id: "b", amount: 700),
        ]
    )

    #expect(flow.unallocated == 0)
}

@Test("unallocated equals total when nothing is allocated")
func unallocatedFullWhenEmpty() {
    let flow = BudgetFlow(total: 1_000)
    #expect(flow.unallocated == 1_000)
}

@Test("unallocated is zero when fully allocated")
func unallocatedZeroWhenExact() {
    let flow = BudgetFlow(
        total: 1_000,
        nodes: [makeNode(id: "a", amount: 1_000)]
    )

    #expect(flow.unallocated == 0)
}

// MARK: - Helpers

private func makeNode(id: String, amount: Decimal) -> BudgetFlowNode {
    BudgetFlowNode(
        id: id,
        labelKey: id,
        amount: amount,
        ratio: 0,
        colorName: "mint",
        symbolName: "circle"
    )
}
