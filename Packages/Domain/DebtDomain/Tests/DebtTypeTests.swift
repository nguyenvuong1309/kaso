import Foundation
import Testing
@testable import DebtDomain

@Suite("DebtType")
struct DebtTypeTests {
    @Test("allCases contains all seven debt types")
    func allCasesCount() {
        #expect(DebtType.allCases.count == 7)
        #expect(Set(DebtType.allCases) == Set([
            .mortgage, .autoLoan, .personalLoan, .creditCard, .studentLoan, .bnpl, .other,
        ]))
    }

    @Test("id equals raw value")
    func idMatchesRawValue() {
        for type in DebtType.allCases {
            #expect(type.id == type.rawValue)
        }
    }

    @Test("nameKey is namespaced by raw value")
    func nameKeyFormat() {
        #expect(DebtType.mortgage.nameKey == "debt.type.mortgage")
        #expect(DebtType.bnpl.nameKey == "debt.type.bnpl")
        for type in DebtType.allCases {
            #expect(type.nameKey == "debt.type.\(type.rawValue)")
        }
    }

    @Test("symbolName is non-empty and unique per case")
    func symbolNames() {
        let symbols = DebtType.allCases.map(\.symbolName)
        #expect(symbols.allSatisfy { !$0.isEmpty })
        #expect(DebtType.creditCard.symbolName == "creditcard")
        #expect(DebtType.mortgage.symbolName == "house.lodge")
    }

    @Test("colorName provides a color token for each case")
    func colorNames() {
        #expect(DebtType.mortgage.colorName == "brown")
        #expect(DebtType.creditCard.colorName == "red")
        #expect(DebtType.other.colorName == "gray")
        #expect(DebtType.allCases.map(\.colorName).allSatisfy { !$0.isEmpty })
    }

    @Test("round-trips through Codable using raw value")
    func codableRoundTrip() throws {
        for type in DebtType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(DebtType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("decodes from raw string value")
    func decodeFromRawString() throws {
        let data = Data("\"studentLoan\"".utf8)
        let decoded = try JSONDecoder().decode(DebtType.self, from: data)
        #expect(decoded == .studentLoan)
    }
}
