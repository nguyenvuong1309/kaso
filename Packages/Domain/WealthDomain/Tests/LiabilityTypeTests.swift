import Foundation
import Testing
@testable import WealthDomain

@Test("liability type exposes all cases in declared order")
func liabilityTypeAllCases() {
    #expect(LiabilityType.allCases == [
        .creditCard,
        .personalLoan,
        .mortgage,
        .autoLoan,
        .studentLoan,
        .bnpl,
        .other,
    ])
}

@Test("liability type id equals raw value")
func liabilityTypeIdentifier() {
    for type in LiabilityType.allCases {
        #expect(type.id == type.rawValue)
    }
}

@Test("liability type name key is namespaced by raw value")
func liabilityTypeNameKey() {
    #expect(LiabilityType.creditCard.nameKey == "wealth.liability.type.creditCard")
    #expect(LiabilityType.mortgage.nameKey == "wealth.liability.type.mortgage")
    #expect(LiabilityType.bnpl.nameKey == "wealth.liability.type.bnpl")
    #expect(LiabilityType.other.nameKey == "wealth.liability.type.other")
}

@Test("liability type provides a distinct symbol for every case")
func liabilityTypeSymbolNames() {
    #expect(LiabilityType.creditCard.symbolName == "creditcard")
    #expect(LiabilityType.personalLoan.symbolName == "person.crop.circle.badge.minus")
    #expect(LiabilityType.mortgage.symbolName == "house.lodge")
    #expect(LiabilityType.autoLoan.symbolName == "car.fill")
    #expect(LiabilityType.studentLoan.symbolName == "graduationcap")
    #expect(LiabilityType.bnpl.symbolName == "cart.badge.minus")
    #expect(LiabilityType.other.symbolName == "doc.text")

    let symbols = LiabilityType.allCases.map(\.symbolName)
    #expect(Set(symbols).count == LiabilityType.allCases.count)
}

@Test("liability type provides a color for every case")
func liabilityTypeColorNames() {
    #expect(LiabilityType.creditCard.colorName == "red")
    #expect(LiabilityType.personalLoan.colorName == "orange")
    #expect(LiabilityType.mortgage.colorName == "brown")
    #expect(LiabilityType.autoLoan.colorName == "indigo")
    #expect(LiabilityType.studentLoan.colorName == "purple")
    #expect(LiabilityType.bnpl.colorName == "pink")
    #expect(LiabilityType.other.colorName == "gray")
}

@Test("liability type round-trips through Codable")
func liabilityTypeCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for type in LiabilityType.allCases {
        let data = try encoder.encode(type)
        let decoded = try decoder.decode(LiabilityType.self, from: data)
        #expect(decoded == type)
    }
}
