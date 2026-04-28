import Foundation
import Testing
import TransactionDomain
@testable import GamificationDomain

@Test("each achievement kind exposes a distinct title key")
func achievementKindsExposeDistinctKeys() {
    let titleKeys = AchievementKind.allCases.map(\.titleKey)
    let unique = Set(titleKeys)
    #expect(titleKeys.count == unique.count)
}

@Test("category groups every achievement kind")
func categoryGroupsAllKinds() {
    let allCovered = AchievementKind.allCases.allSatisfy { kind in
        AchievementCategory.allCases.contains(kind.category)
    }
    #expect(allCovered)
    for category in AchievementCategory.allCases {
        let inCategory = AchievementKind.allCases.filter { $0.category == category }
        #expect(inCategory.isEmpty == false)
    }
}

@Test("first transaction unlocks first steps achievement")
func firstStepsUnlocksOnFirstTransaction() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 100_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.firstSteps))
    let firstStepsProgress = try #require(
        evaluation.progresses.first { $0.kind == .firstSteps }
    )
    #expect(firstStepsProgress.isUnlocked)
    #expect(firstStepsProgress.currentValue == 1)
}

@Test("week warrior unlocks when streak reaches seven days")
func weekWarriorUnlocksAtSevenDayStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let profile = GamificationProfile(currentStreak: 7, longestStreak: 7)

    let evaluation = AchievementCalculator.evaluate(
        profile: profile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.weekWarrior))
    #expect(evaluation.newlyUnlocked.contains(.monthlyMaster) == false)
    #expect(evaluation.newlyUnlocked.contains(.centuryClub) == false)
}

@Test("monthly master and century club unlock at higher streaks")
func higherStreakAchievementsUnlock() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 7, day: 12, calendar: calendar)

    let monthly = AchievementCalculator.evaluate(
        profile: GamificationProfile(currentStreak: 30, longestStreak: 30),
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )
    #expect(monthly.newlyUnlocked.contains(.monthlyMaster))
    #expect(monthly.newlyUnlocked.contains(.centuryClub) == false)

    let century = AchievementCalculator.evaluate(
        profile: GamificationProfile(currentStreak: 100, longestStreak: 100),
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )
    #expect(century.newlyUnlocked.contains(.centuryClub))
}

@Test("no spend novice counts past 30 days with no expense but with activity")
func noSpendNoviceCountsRecentDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let yesterday = try makeDate(year: 2026, month: 4, day: 9, calendar: calendar)
    let twoDaysAgo = try makeDate(year: 2026, month: 4, day: 8, calendar: calendar)

    let transactions = [
        Transaction(amount: 12_000_000, kind: .income, category: .salary, occurredAt: today),
        Transaction(amount: 500_000, kind: .income, category: .other, occurredAt: yesterday),
        Transaction(amount: 250_000, kind: .income, category: .other, occurredAt: twoDaysAgo),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: today,
        calendar: calendar
    )

    let noSpend = try #require(
        evaluation.progresses.first { $0.kind == .noSpendNovice }
    )
    #expect(noSpend.currentValue == 3)
    #expect(noSpend.isUnlocked)
    #expect(evaluation.newlyUnlocked.contains(.noSpendNovice))
}

@Test("no spend novice does not count days that have any expense")
func noSpendNoviceIgnoresExpenseDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let transactions = [
        Transaction(amount: 12_000_000, kind: .income, category: .salary, occurredAt: today),
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: today),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: today,
        calendar: calendar
    )

    let noSpend = try #require(
        evaluation.progresses.first { $0.kind == .noSpendNovice }
    )
    #expect(noSpend.currentValue == 0)
    #expect(noSpend.isUnlocked == false)
}

@Test("budget guardian unlocks after five budget respected events")
func budgetGuardianUnlocksAfterFiveEvents() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let events = (0..<5).map { offset in
        RewardEvent(
            kind: .budgetRespected,
            earnedAt: referenceDate.addingTimeInterval(TimeInterval(-offset * 86_400))
        )
    }
    let profile = GamificationProfile(rewardEvents: events)

    let evaluation = AchievementCalculator.evaluate(
        profile: profile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.budgetGuardian))
}

@Test("category collector unlocks when five distinct categories are used")
func categoryCollectorUnlocks() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let categories: [TransactionCategory] = [
        .food, .transport, .housing, .entertainment, .health,
    ]
    let transactions = categories.map { category in
        Transaction(amount: 10_000, kind: .expense, category: category, occurredAt: today)
    }

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.categoryCollector))
}

@Test("dual logger unlocks when income and expense recorded same day")
func dualLoggerUnlocksOnSameDayIncomeAndExpense() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let transactions = [
        Transaction(amount: 100_000, kind: .expense, category: .food, occurredAt: today),
        Transaction(amount: 5_000_000, kind: .income, category: .salary, occurredAt: today),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.dualLogger))
}

@Test("early bird unlocks for transaction before 7am")
func earlyBirdUnlocksForEarlyTransaction() throws {
    let calendar = Calendar(identifier: .gregorian)
    let earlyHour = try makeDate(year: 2026, month: 4, day: 10, hour: 6, calendar: calendar)
    let transactions = [
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: earlyHour),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: earlyHour,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.earlyBird))
    #expect(evaluation.newlyUnlocked.contains(.nightOwl) == false)
}

@Test("night owl unlocks for transaction after 22:00")
func nightOwlUnlocksForLateTransaction() throws {
    let calendar = Calendar(identifier: .gregorian)
    let lateHour = try makeDate(year: 2026, month: 4, day: 10, hour: 23, calendar: calendar)
    let transactions = [
        Transaction(amount: 80_000, kind: .expense, category: .food, occurredAt: lateHour),
    ]

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: lateHour,
        calendar: calendar
    )

    #expect(evaluation.newlyUnlocked.contains(.nightOwl))
    #expect(evaluation.newlyUnlocked.contains(.earlyBird) == false)
}

@Test("reward collector tiers track total points")
func rewardCollectorTracksPoints() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)

    let lowProfile = GamificationProfile(totalPoints: 200)
    let lowEval = AchievementCalculator.evaluate(
        profile: lowProfile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )
    #expect(lowEval.newlyUnlocked.contains(.rewardCollector) == false)

    let midProfile = GamificationProfile(totalPoints: 600)
    let midEval = AchievementCalculator.evaluate(
        profile: midProfile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )
    #expect(midEval.newlyUnlocked.contains(.rewardCollector))
    #expect(midEval.newlyUnlocked.contains(.eliteCollector) == false)

    let highProfile = GamificationProfile(totalPoints: 2_500)
    let highEval = AchievementCalculator.evaluate(
        profile: highProfile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )
    #expect(highEval.newlyUnlocked.contains(.eliteCollector))
}

@Test("already unlocked achievements stay unlocked but are not in newlyUnlocked")
func alreadyUnlockedAchievementsAreSticky() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 0,
        longestStreak: 12,
        unlockedAchievements: [.weekWarrior]
    )

    let evaluation = AchievementCalculator.evaluate(
        profile: profile,
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    let weekWarrior = try #require(
        evaluation.progresses.first { $0.kind == .weekWarrior }
    )
    #expect(weekWarrior.isUnlocked)
    #expect(evaluation.newlyUnlocked.contains(.weekWarrior) == false)
}

@Test("gamification calculator surfaces achievement progress with reward events")
func gamificationCalculatorSurfacesAchievements() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let transactions = [
        Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: today),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.achievementProgresses.isEmpty == false)
    #expect(evaluation.newlyUnlockedAchievements.contains(.firstSteps))
    #expect(evaluation.profile.unlockedAchievements.contains(.firstSteps))
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
