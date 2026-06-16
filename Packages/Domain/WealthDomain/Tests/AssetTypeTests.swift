import Foundation
import Testing
@testable import WealthDomain

@Test("asset type exposes all cases in declared order")
func assetTypeAllCases() {
    #expect(AssetType.allCases == [
        .cash,
        .bankSavings,
        .termDeposit,
        .investment,
        .realEstate,
        .vehicle,
        .other,
    ])
}

@Test("asset type id equals raw value")
func assetTypeIdentifier() {
    for type in AssetType.allCases {
        #expect(type.id == type.rawValue)
    }
}

@Test("asset type name key is namespaced by raw value")
func assetTypeNameKey() {
    #expect(AssetType.cash.nameKey == "wealth.asset.type.cash")
    #expect(AssetType.bankSavings.nameKey == "wealth.asset.type.bankSavings")
    #expect(AssetType.realEstate.nameKey == "wealth.asset.type.realEstate")
    #expect(AssetType.other.nameKey == "wealth.asset.type.other")
}

@Test("asset type provides a distinct symbol for every case")
func assetTypeSymbolNames() {
    #expect(AssetType.cash.symbolName == "banknote")
    #expect(AssetType.bankSavings.symbolName == "building.columns")
    #expect(AssetType.termDeposit.symbolName == "lock.shield")
    #expect(AssetType.investment.symbolName == "chart.line.uptrend.xyaxis")
    #expect(AssetType.realEstate.symbolName == "house")
    #expect(AssetType.vehicle.symbolName == "car")
    #expect(AssetType.other.symbolName == "shippingbox")

    let symbols = AssetType.allCases.map(\.symbolName)
    #expect(Set(symbols).count == AssetType.allCases.count)
}

@Test("asset type provides a color for every case")
func assetTypeColorNames() {
    #expect(AssetType.cash.colorName == "green")
    #expect(AssetType.bankSavings.colorName == "blue")
    #expect(AssetType.termDeposit.colorName == "indigo")
    #expect(AssetType.investment.colorName == "purple")
    #expect(AssetType.realEstate.colorName == "brown")
    #expect(AssetType.vehicle.colorName == "orange")
    #expect(AssetType.other.colorName == "gray")
}

@Test("asset type round-trips through Codable")
func assetTypeCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for type in AssetType.allCases {
        let data = try encoder.encode(type)
        let decoded = try decoder.decode(AssetType.self, from: data)
        #expect(decoded == type)
    }
}
