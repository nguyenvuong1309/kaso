import Foundation
import Testing
@testable import GamificationDomain

@Test("level falls back to newcomer when streak is zero")
func levelFallsBackToNewcomer() {
    #expect(StreakLevel.level(for: 0) == .newcomer)
    #expect(StreakLevel.level(for: 2) == .newcomer)
}

@Test("level escalates with streak length")
func levelEscalatesWithStreak() {
    #expect(StreakLevel.level(for: 3) == .consistent)
    #expect(StreakLevel.level(for: 6) == .consistent)
    #expect(StreakLevel.level(for: 7) == .disciplined)
    #expect(StreakLevel.level(for: 29) == .disciplined)
    #expect(StreakLevel.level(for: 30) == .master)
    #expect(StreakLevel.level(for: 99) == .master)
    #expect(StreakLevel.level(for: 100) == .legendary)
    #expect(StreakLevel.level(for: 365) == .legendary)
}

@Test("nextLevel chains through all levels and stops at legendary")
func nextLevelChain() {
    #expect(StreakLevel.newcomer.nextLevel == .consistent)
    #expect(StreakLevel.consistent.nextLevel == .disciplined)
    #expect(StreakLevel.disciplined.nextLevel == .master)
    #expect(StreakLevel.master.nextLevel == .legendary)
    #expect(StreakLevel.legendary.nextLevel == nil)
}
