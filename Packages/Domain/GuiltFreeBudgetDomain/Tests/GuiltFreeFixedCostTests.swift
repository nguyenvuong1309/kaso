import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

// MARK: - GuiltFreeFixedCostKind

@Test("fixed cost kind id equals its raw value")
func fixedCostKindIdMatchesRawValue() {
    for kind in GuiltFreeFixedCostKind.allCases {
        #expect(kind.id == kind.rawValue)
    }
}

@Test("fixed cost kind name key is namespaced by raw value")
func fixedCostKindNameKey() {
    #expect(GuiltFreeFixedCostKind.housing.nameKey == "guiltFree.fixedCost.kind.housing")
    #expect(GuiltFreeFixedCostKind.emergencyFund.nameKey == "guiltFree.fixedCost.kind.emergencyFund")
    #expect(GuiltFreeFixedCostKind.other.nameKey == "guiltFree.fixedCost.kind.other")
}

@Test("each fixed cost kind exposes a distinct SF symbol name")
func fixedCostKindSymbolNames() {
    #expect(GuiltFreeFixedCostKind.housing.symbolName == "house.fill")
    #expect(GuiltFreeFixedCostKind.utilities.symbolName == "bolt.fill")
    #expect(GuiltFreeFixedCostKind.insurance.symbolName == "cross.case.fill")
    #expect(GuiltFreeFixedCostKind.loanRepayment.symbolName == "banknote.fill")
    #expect(GuiltFreeFixedCostKind.savings.symbolName == "leaf.fill")
    #expect(GuiltFreeFixedCostKind.emergencyFund.symbolName == "shield.lefthalf.filled")
    #expect(GuiltFreeFixedCostKind.other.symbolName == "ellipsis.circle.fill")
}

@Test("symbol names are unique across all kinds")
func fixedCostKindSymbolNamesUnique() {
    let symbols = GuiltFreeFixedCostKind.allCases.map(\.symbolName)
    let unique = Set(symbols)
    #expect(symbols.count == unique.count)
}

@Test("all cases lists the seven expected kinds")
func fixedCostKindAllCases() {
    #expect(GuiltFreeFixedCostKind.allCases.count == 7)
    #expect(GuiltFreeFixedCostKind.allCases.contains(.housing))
    #expect(GuiltFreeFixedCostKind.allCases.contains(.emergencyFund))
}

@Test("fixed cost kind round-trips through Codable")
func fixedCostKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for kind in GuiltFreeFixedCostKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(GuiltFreeFixedCostKind.self, from: data)
        #expect(decoded == kind)
    }
}

// MARK: - GuiltFreeFixedCost

@Test("fixed cost init defaults kind to other")
func fixedCostDefaultKind() {
    let cost = GuiltFreeFixedCost(name: "Khác", amount: 1_000_000)
    #expect(cost.kind == .other)
}

@Test("fixed cost stores provided id, name, amount, and kind")
func fixedCostStoresFields() throws {
    let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let cost = GuiltFreeFixedCost(id: id, name: "Tiền nhà", amount: 8_000_000, kind: .housing)

    #expect(cost.id == id)
    #expect(cost.name == "Tiền nhà")
    #expect(cost.amount == 8_000_000)
    #expect(cost.kind == .housing)
}

@Test("fixed cost id conforms to Identifiable")
func fixedCostIdentifiable() throws {
    let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    let cost = GuiltFreeFixedCost(id: id, name: "X", amount: 1, kind: .other)
    let identifiableID: GuiltFreeFixedCost.ID = cost.id
    #expect(identifiableID == id)
}

@Test("fixed costs with same fields are equal and differ otherwise")
func fixedCostEquatable() throws {
    let id = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
    let lhs = GuiltFreeFixedCost(id: id, name: "A", amount: 100, kind: .utilities)
    let rhs = GuiltFreeFixedCost(id: id, name: "A", amount: 100, kind: .utilities)
    var different = rhs
    different.amount = 200

    #expect(lhs == rhs)
    #expect(lhs != different)
}

@Test("fixed cost round-trips through Codable preserving all fields")
func fixedCostCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
    let cost = GuiltFreeFixedCost(id: id, name: "Bảo hiểm", amount: 1_500_000, kind: .insurance)

    let data = try JSONEncoder().encode(cost)
    let decoded = try JSONDecoder().decode(GuiltFreeFixedCost.self, from: data)

    #expect(decoded == cost)
    #expect(decoded.id == id)
    #expect(decoded.kind == .insurance)
}
