import Foundation
import Testing
@testable import GamificationDomain

@Test("profile financialLevel resolves from total points")
func profileFinancialLevelResolvesFromPoints() {
    #expect(GamificationProfile(totalPoints: 0).financialLevel == .sprout)
    #expect(GamificationProfile(totalPoints: 800).financialLevel == .silver)
    #expect(GamificationProfile(totalPoints: 30_000).financialLevel == .legend)
}

@Test("profile financialLevelProgress mirrors its total points")
func profileFinancialLevelProgressMirrorsTotal() {
    let profile = GamificationProfile(totalPoints: 600)
    #expect(profile.financialLevelProgress.totalPoints == 600)
    #expect(profile.financialLevelProgress.level == .bronze)
    #expect(profile.financialLevelProgress.pointsNeededForNext == 200)
}

@Test("profile daysToNextLevel is nil at the top streak level")
func profileDaysToNextLevelNilAtTop() {
    let profile = GamificationProfile(currentStreak: 120)
    #expect(profile.level == .legendary)
    #expect(profile.nextLevel == nil)
    #expect(profile.daysToNextLevel == nil)
}

@Test("profile codable round-trips through json")
func profileCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 5,
        longestStreak: 9,
        totalPoints: 1_234,
        lastActivityDate: date,
        lastEvaluatedDate: date,
        rewardEvents: [RewardEvent(kind: .dailyEntry, earnedAt: date)],
        unlockedMilestones: [.streakMilestone3],
        unlockedAchievements: [.firstSteps, .weekWarrior],
        lastNotifiedFinancialLevel: .bronze,
        activeWeeklyChallenge: WeeklyChallenge(kind: .dailyStreak, weekStart: date),
        completedWeeklyChallenges: [WeeklyChallenge(kind: .noSpendDays, weekStart: date)]
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(profile)
    let decoded = try decoder.decode(GamificationProfile.self, from: data)
    #expect(decoded == profile)
}

@Test("profile decodes legacy payload with only required scalar keys")
func profileDecodesMinimalPayload() throws {
    let json = """
    {
        "currentStreak": 3,
        "longestStreak": 4,
        "totalPoints": 120
    }
    """
    let data = try #require(json.data(using: .utf8))
    let decoded = try JSONDecoder().decode(GamificationProfile.self, from: data)
    #expect(decoded.currentStreak == 3)
    #expect(decoded.longestStreak == 4)
    #expect(decoded.totalPoints == 120)
    #expect(decoded.lastActivityDate == nil)
    #expect(decoded.lastEvaluatedDate == nil)
    #expect(decoded.rewardEvents.isEmpty)
    #expect(decoded.unlockedMilestones.isEmpty)
    #expect(decoded.unlockedAchievements.isEmpty)
    #expect(decoded.lastNotifiedFinancialLevel == nil)
    #expect(decoded.activeWeeklyChallenge == nil)
    #expect(decoded.completedWeeklyChallenges.isEmpty)
}

@Test("default profile starts empty at the lowest tiers")
func defaultProfileStartsEmpty() {
    let profile = GamificationProfile()
    #expect(profile.currentStreak == 0)
    #expect(profile.longestStreak == 0)
    #expect(profile.totalPoints == 0)
    #expect(profile.level == .newcomer)
    #expect(profile.financialLevel == .sprout)
    #expect(profile.progressToNextLevel == 0)
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
