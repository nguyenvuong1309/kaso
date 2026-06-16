import Foundation
import Testing
@testable import GamificationDomain

@Test("weekly challenge kind id equals its raw value")
func weeklyChallengeKindIdMatchesRawValue() {
    for kind in WeeklyChallengeKind.allCases {
        #expect(kind.id == kind.rawValue)
    }
}

@Test("weekly challenge kind exposes the expected default targets")
func weeklyChallengeKindDefaultTargets() {
    #expect(WeeklyChallengeKind.dailyStreak.defaultTarget == 7)
    #expect(WeeklyChallengeKind.noSpendDays.defaultTarget == 3)
    #expect(WeeklyChallengeKind.budgetKeeper.defaultTarget == 5)
    #expect(WeeklyChallengeKind.categoryVariety.defaultTarget == 4)
    #expect(WeeklyChallengeKind.incomeLogger.defaultTarget == 1)
}

@Test("weekly challenge kind exposes the expected reward points")
func weeklyChallengeKindRewardPoints() {
    #expect(WeeklyChallengeKind.dailyStreak.rewardPoints == 200)
    #expect(WeeklyChallengeKind.noSpendDays.rewardPoints == 150)
    #expect(WeeklyChallengeKind.budgetKeeper.rewardPoints == 200)
    #expect(WeeklyChallengeKind.categoryVariety.rewardPoints == 100)
    #expect(WeeklyChallengeKind.incomeLogger.rewardPoints == 80)
}

@Test("weekly challenge kind exposes distinct symbols and localization keys")
func weeklyChallengeKindMetadata() {
    let symbols = WeeklyChallengeKind.allCases.map(\.symbolName)
    #expect(symbols.allSatisfy { !$0.isEmpty })
    #expect(Set(symbols).count == symbols.count)
    #expect(WeeklyChallengeKind.budgetKeeper.titleKey == "gamification.weeklyChallenge.budgetKeeper.title")
    #expect(
        WeeklyChallengeKind.incomeLogger.descriptionKey
            == "gamification.weeklyChallenge.incomeLogger.description"
    )
}

@Test("weekly challenge defaults its target to the kind default")
func weeklyChallengeDefaultsTargetToKind() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    #expect(challenge.target == WeeklyChallengeKind.dailyStreak.defaultTarget)
}

@Test("weekly challenge accepts an explicit target override")
func weeklyChallengeAcceptsTargetOverride() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart, target: 2)
    #expect(challenge.target == 2)
}

@Test("weekly challenge clamps negative progress to zero")
func weeklyChallengeClampsNegativeProgress() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart, currentProgress: -3)
    #expect(challenge.currentProgress == 0)
}

@Test("weekly challenge isCompleted tracks the completion date")
func weeklyChallengeIsCompletedTracksDate() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let completedAt = try makeDate(year: 2026, month: 4, day: 29, calendar: calendar)
    let pending = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let done = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart, completedAt: completedAt)
    #expect(pending.isCompleted == false)
    #expect(done.isCompleted)
}

@Test("weekly challenge ratio is normalized and capped at one")
func weeklyChallengeRatio() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let half = WeeklyChallenge(kind: .budgetKeeper, weekStart: weekStart, currentProgress: 2)
    #expect(half.ratio == 0.4)
    let over = WeeklyChallenge(kind: .budgetKeeper, weekStart: weekStart, currentProgress: 99)
    #expect(over.ratio == 1)
}

@Test("weekly challenge display progress never exceeds the target")
func weeklyChallengeDisplayProgressCaps() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .noSpendDays, weekStart: weekStart, currentProgress: 10)
    #expect(challenge.displayProgress == 3)
}

@Test("weekly challenge week end is seven days after the start")
func weeklyChallengeWeekEnd() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let expectedEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)
    #expect(challenge.weekEnd(calendar: calendar) == expectedEnd)
}

@Test("weekly challenge days remaining clamps to zero past the week end")
func weeklyChallengeDaysRemainingClampsToZero() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let afterWeek = try makeDate(year: 2026, month: 5, day: 10, calendar: calendar)
    #expect(challenge.daysRemaining(referenceDate: afterWeek, calendar: calendar) == 0)
}

@Test("weekly challenge codable round-trips through json")
func weeklyChallengeCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let completedAt = try makeDate(year: 2026, month: 4, day: 30, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1"))
    let challenge = WeeklyChallenge(
        id: id,
        kind: .categoryVariety,
        weekStart: weekStart,
        target: 4,
        currentProgress: 4,
        completedAt: completedAt
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try encoder.encode(challenge)
    let decoded = try decoder.decode(WeeklyChallenge.self, from: data)
    #expect(decoded == challenge)
}

@Test("weekly challenge kind codable round-trips through raw value")
func weeklyChallengeKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for kind in WeeklyChallengeKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(WeeklyChallengeKind.self, from: data)
        #expect(decoded == kind)
    }
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
