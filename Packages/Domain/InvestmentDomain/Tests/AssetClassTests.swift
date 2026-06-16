import Foundation
import Testing
@testable import InvestmentDomain

struct AssetClassTests {
    @Test("all cases are present and identifiable by raw value")
    func allCasesAndIdentity() {
        #expect(AssetClass.allCases.count == 8)
        for assetClass in AssetClass.allCases {
            #expect(assetClass.id == assetClass.rawValue)
        }
    }

    @Test("raw values are the expected stable strings")
    func rawValues() {
        #expect(AssetClass.stock.rawValue == "stock")
        #expect(AssetClass.etf.rawValue == "etf")
        #expect(AssetClass.bond.rawValue == "bond")
        #expect(AssetClass.mutualFund.rawValue == "mutualFund")
        #expect(AssetClass.crypto.rawValue == "crypto")
        #expect(AssetClass.gold.rawValue == "gold")
        #expect(AssetClass.cashEquivalent.rawValue == "cashEquivalent")
        #expect(AssetClass.other.rawValue == "other")
    }

    @Test("name key is namespaced per raw value")
    func nameKey() {
        #expect(AssetClass.stock.nameKey == "investment.assetClass.stock")
        #expect(AssetClass.cashEquivalent.nameKey == "investment.assetClass.cashEquivalent")
        for assetClass in AssetClass.allCases {
            #expect(assetClass.nameKey == "investment.assetClass.\(assetClass.rawValue)")
        }
    }

    @Test("symbol name is unique and non-empty for every case")
    func symbolName() {
        let symbols = AssetClass.allCases.map(\.symbolName)
        #expect(symbols.allSatisfy { $0.isEmpty == false })
        #expect(Set(symbols).count == AssetClass.allCases.count)
        #expect(AssetClass.stock.symbolName == "chart.line.uptrend.xyaxis")
        #expect(AssetClass.crypto.symbolName == "bitcoinsign.circle")
        #expect(AssetClass.other.symbolName == "questionmark.circle")
    }

    @Test("color name is unique and non-empty for every case")
    func colorName() {
        let colors = AssetClass.allCases.map(\.colorName)
        #expect(colors.allSatisfy { $0.isEmpty == false })
        #expect(Set(colors).count == AssetClass.allCases.count)
        #expect(AssetClass.stock.colorName == "blue")
        #expect(AssetClass.gold.colorName == "brown")
        #expect(AssetClass.other.colorName == "gray")
    }

    @Test("codable round-trip preserves case")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for assetClass in AssetClass.allCases {
            let data = try encoder.encode(assetClass)
            let decoded = try decoder.decode(AssetClass.self, from: data)
            #expect(decoded == assetClass)
        }
    }

    @Test("decodes from raw string value")
    func decodeFromRawString() throws {
        let data = Data("\"mutualFund\"".utf8)
        let decoded = try JSONDecoder().decode(AssetClass.self, from: data)
        #expect(decoded == .mutualFund)
    }
}
