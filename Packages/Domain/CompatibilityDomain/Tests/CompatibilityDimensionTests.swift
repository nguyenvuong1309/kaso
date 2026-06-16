import Foundation
import Testing
@testable import CompatibilityDomain

@Test("dimension exposes all six cases in stable order")
func dimensionHasAllSixCases() {
    #expect(CompatibilityDimension.allCases.count == 6)
    #expect(CompatibilityDimension.allCases == [
        .spendingStyle,
        .riskTolerance,
        .debtAttitude,
        .splittingApproach,
        .familySupport,
        .futureGoals,
    ])
}

@Test("dimension raw values match expected identifiers")
func dimensionRawValues() {
    #expect(CompatibilityDimension.spendingStyle.rawValue == "spendingStyle")
    #expect(CompatibilityDimension.riskTolerance.rawValue == "riskTolerance")
    #expect(CompatibilityDimension.debtAttitude.rawValue == "debtAttitude")
    #expect(CompatibilityDimension.splittingApproach.rawValue == "splittingApproach")
    #expect(CompatibilityDimension.familySupport.rawValue == "familySupport")
    #expect(CompatibilityDimension.futureGoals.rawValue == "futureGoals")
}

@Test("dimension id equals raw value")
func dimensionIdEqualsRawValue() {
    for dimension in CompatibilityDimension.allCases {
        #expect(dimension.id == dimension.rawValue)
    }
}

@Test("dimension title key is namespaced by raw value")
func dimensionTitleKey() {
    #expect(CompatibilityDimension.spendingStyle.titleKey == "compatibility.dimension.spendingStyle")
    #expect(CompatibilityDimension.futureGoals.titleKey == "compatibility.dimension.futureGoals")
    for dimension in CompatibilityDimension.allCases {
        #expect(dimension.titleKey == "compatibility.dimension.\(dimension.rawValue)")
    }
}

@Test("dimension symbol names map to expected SF Symbols")
func dimensionSymbolNames() {
    #expect(CompatibilityDimension.spendingStyle.symbolName == "cart")
    #expect(CompatibilityDimension.riskTolerance.symbolName == "chart.line.uptrend.xyaxis")
    #expect(CompatibilityDimension.debtAttitude.symbolName == "creditcard")
    #expect(CompatibilityDimension.splittingApproach.symbolName == "person.2")
    #expect(CompatibilityDimension.familySupport.symbolName == "heart")
    #expect(CompatibilityDimension.futureGoals.symbolName == "target")
}

@Test("dimension color names map to expected palette entries")
func dimensionColorNames() {
    #expect(CompatibilityDimension.spendingStyle.colorName == "mint")
    #expect(CompatibilityDimension.riskTolerance.colorName == "orange")
    #expect(CompatibilityDimension.debtAttitude.colorName == "purple")
    #expect(CompatibilityDimension.splittingApproach.colorName == "blue")
    #expect(CompatibilityDimension.familySupport.colorName == "pink")
    #expect(CompatibilityDimension.futureGoals.colorName == "green")
}

@Test("every dimension produces a non-empty symbol and color name")
func dimensionMetadataIsNonEmpty() {
    for dimension in CompatibilityDimension.allCases {
        #expect(dimension.symbolName.isEmpty == false)
        #expect(dimension.colorName.isEmpty == false)
    }
}

@Test("dimension round-trips through Codable")
func dimensionCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for dimension in CompatibilityDimension.allCases {
        let data = try encoder.encode(dimension)
        let decoded = try decoder.decode(CompatibilityDimension.self, from: data)
        #expect(decoded == dimension)
    }
}

@Test("dimension decodes from its raw string value")
func dimensionDecodesFromRawValue() throws {
    let data = Data("\"debtAttitude\"".utf8)
    let decoded = try JSONDecoder().decode(CompatibilityDimension.self, from: data)
    #expect(decoded == .debtAttitude)
}
