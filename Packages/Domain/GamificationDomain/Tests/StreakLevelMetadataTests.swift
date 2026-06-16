import Foundation
import Testing
@testable import GamificationDomain

@Test("streak level id equals its raw value")
func streakLevelIdMatchesRawValue() {
    for level in StreakLevel.allCases {
        #expect(level.id == level.rawValue)
    }
}

@Test("streak level minimum days match the tier thresholds")
func streakLevelMinimumDays() {
    #expect(StreakLevel.newcomer.minStreakDays == 0)
    #expect(StreakLevel.consistent.minStreakDays == 3)
    #expect(StreakLevel.disciplined.minStreakDays == 7)
    #expect(StreakLevel.master.minStreakDays == 30)
    #expect(StreakLevel.legendary.minStreakDays == 100)
}

@Test("streak level exposes namespaced distinct localization keys")
func streakLevelLocalizationKeys() {
    #expect(StreakLevel.master.nameKey == "gamification.level.master")
    #expect(StreakLevel.master.descriptionKey == "gamification.level.master.description")
    let nameKeys = StreakLevel.allCases.map(\.nameKey)
    #expect(Set(nameKeys).count == nameKeys.count)
}

@Test("streak level falls back to newcomer for negative streaks")
func streakLevelFallsBackForNegativeStreak() {
    #expect(StreakLevel.level(for: -10) == .newcomer)
}

@Test("streak level codable round-trips through raw value")
func streakLevelCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for level in StreakLevel.allCases {
        let data = try encoder.encode(level)
        let decoded = try decoder.decode(StreakLevel.self, from: data)
        #expect(decoded == level)
    }
}
