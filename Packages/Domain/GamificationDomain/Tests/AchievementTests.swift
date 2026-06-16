import Foundation
import Testing
@testable import GamificationDomain

@Test("achievement category id equals its raw value")
func achievementCategoryIdMatchesRawValue() {
    for category in AchievementCategory.allCases {
        #expect(category.id == category.rawValue)
    }
}

@Test("achievement category exposes namespaced localization keys")
func achievementCategoryLocalizationKeys() {
    #expect(AchievementCategory.consistency.titleKey == "gamification.achievement.category.consistency")
    #expect(
        AchievementCategory.discipline.descriptionKey
            == "gamification.achievement.category.discipline.description"
    )
    let titleKeys = AchievementCategory.allCases.map(\.titleKey)
    #expect(Set(titleKeys).count == titleKeys.count)
}

@Test("achievement kind id equals its raw value")
func achievementKindIdMatchesRawValue() {
    for kind in AchievementKind.allCases {
        #expect(kind.id == kind.rawValue)
    }
}

@Test("achievement kind exposes namespaced title and description keys")
func achievementKindLocalizationKeys() {
    #expect(AchievementKind.firstSteps.titleKey == "gamification.achievement.firstSteps.title")
    #expect(
        AchievementKind.centuryClub.descriptionKey
            == "gamification.achievement.centuryClub.description"
    )
    let descriptionKeys = AchievementKind.allCases.map(\.descriptionKey)
    #expect(Set(descriptionKeys).count == descriptionKeys.count)
}

@Test("achievement kind maps every case to a category")
func achievementKindCategoryMapping() {
    #expect(AchievementKind.firstSteps.category == .consistency)
    #expect(AchievementKind.weekWarrior.category == .consistency)
    #expect(AchievementKind.monthlyMaster.category == .consistency)
    #expect(AchievementKind.centuryClub.category == .consistency)
    #expect(AchievementKind.noSpendNovice.category == .discipline)
    #expect(AchievementKind.noSpendChampion.category == .discipline)
    #expect(AchievementKind.budgetGuardian.category == .discipline)
    #expect(AchievementKind.categoryCollector.category == .explorer)
    #expect(AchievementKind.dualLogger.category == .explorer)
    #expect(AchievementKind.earlyBird.category == .explorer)
    #expect(AchievementKind.nightOwl.category == .explorer)
    #expect(AchievementKind.rewardCollector.category == .rewardTier)
    #expect(AchievementKind.eliteCollector.category == .rewardTier)
}

@Test("achievement kind exposes a non-empty distinct sf symbol per case")
func achievementKindSymbolNames() {
    let symbols = AchievementKind.allCases.map(\.symbolName)
    #expect(symbols.allSatisfy { !$0.isEmpty })
    #expect(Set(symbols).count == symbols.count)
    #expect(AchievementKind.firstSteps.symbolName == "shoeprints.fill")
    #expect(AchievementKind.eliteCollector.symbolName == "rosette")
}

@Test("achievement kind exposes the expected target values")
func achievementKindTargetValues() {
    #expect(AchievementKind.firstSteps.targetValue == 1)
    #expect(AchievementKind.weekWarrior.targetValue == 7)
    #expect(AchievementKind.monthlyMaster.targetValue == 30)
    #expect(AchievementKind.centuryClub.targetValue == 100)
    #expect(AchievementKind.noSpendNovice.targetValue == 3)
    #expect(AchievementKind.noSpendChampion.targetValue == 10)
    #expect(AchievementKind.budgetGuardian.targetValue == 5)
    #expect(AchievementKind.categoryCollector.targetValue == 5)
    #expect(AchievementKind.dualLogger.targetValue == 1)
    #expect(AchievementKind.earlyBird.targetValue == 1)
    #expect(AchievementKind.nightOwl.targetValue == 1)
    #expect(AchievementKind.rewardCollector.targetValue == 500)
    #expect(AchievementKind.eliteCollector.targetValue == 2_000)
}

@Test("achievement category codable round-trips through raw value")
func achievementCategoryCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for category in AchievementCategory.allCases {
        let data = try encoder.encode(category)
        let decoded = try decoder.decode(AchievementCategory.self, from: data)
        #expect(decoded == category)
    }
}

@Test("achievement kind codable round-trips through raw value")
func achievementKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for kind in AchievementKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(AchievementKind.self, from: data)
        #expect(decoded == kind)
    }
}
