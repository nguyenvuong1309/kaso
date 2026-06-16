import Foundation
import Testing
@testable import GamificationDomain

@Test("financial level id equals its raw value")
func financialLevelIdMatchesRawValue() {
    for level in FinancialLevel.allCases {
        #expect(level.id == level.rawValue)
    }
}

@Test("financial level minimum points increase monotonically")
func financialLevelMinimumPointsAreMonotonic() {
    let sorted = FinancialLevel.allCases.sorted { $0.minimumPoints < $1.minimumPoints }
    #expect(sorted == FinancialLevel.allCases)
    #expect(FinancialLevel.sprout.minimumPoints == 0)
    #expect(FinancialLevel.legend.minimumPoints == 25_000)
}

@Test("financial level exposes namespaced distinct localization keys")
func financialLevelLocalizationKeys() {
    #expect(FinancialLevel.gold.nameKey == "gamification.financialLevel.gold")
    #expect(FinancialLevel.gold.descriptionKey == "gamification.financialLevel.gold.description")
    #expect(FinancialLevel.gold.perkKey == "gamification.financialLevel.gold.perk")
    let perkKeys = FinancialLevel.allCases.map(\.perkKey)
    #expect(Set(perkKeys).count == perkKeys.count)
}

@Test("financial level exposes a non-empty distinct sf symbol per case")
func financialLevelSymbolNames() {
    let symbols = FinancialLevel.allCases.map(\.symbolName)
    #expect(symbols.allSatisfy { !$0.isEmpty })
    #expect(Set(symbols).count == symbols.count)
    #expect(FinancialLevel.sprout.symbolName == "leaf.fill")
    #expect(FinancialLevel.legend.symbolName == "sparkles")
}

@Test("financial level codable round-trips through raw value")
func financialLevelCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for level in FinancialLevel.allCases {
        let data = try encoder.encode(level)
        let decoded = try decoder.decode(FinancialLevel.self, from: data)
        #expect(decoded == level)
    }
}

@Test("financial level progress designated init trusts supplied level")
func financialLevelProgressDesignatedInit() {
    let progress = FinancialLevelProgress(level: .gold, totalPoints: 2_500)
    #expect(progress.level == .gold)
    #expect(progress.totalPoints == 2_500)
    #expect(progress.pointsInCurrentLevel == 500)
}

@Test("financial level progress designated init clamps negative totals")
func financialLevelProgressDesignatedInitClampsTotals() {
    let progress = FinancialLevelProgress(level: .sprout, totalPoints: -42)
    #expect(progress.totalPoints == 0)
    #expect(progress.pointsInCurrentLevel == 0)
}

@Test("financial level progress reports exactly zero ratio at a tier boundary")
func financialLevelProgressZeroRatioAtBoundary() {
    let progress = FinancialLevelProgress(totalPoints: 200)
    #expect(progress.level == .bronze)
    #expect(progress.pointsInCurrentLevel == 0)
    #expect(progress.ratio == 0)
    #expect(progress.pointsNeededForNext == 600)
}
