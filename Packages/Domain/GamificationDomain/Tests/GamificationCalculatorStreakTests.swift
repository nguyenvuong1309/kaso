import Foundation
import Testing
import BudgetDomain
import TransactionDomain
@testable import GamificationDomain

@Test("no transactions today leaves a fresh profile at zero streak")
func noEntryTodayKeepsFreshProfileEmpty() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 0)
    #expect(evaluation.profile.lastActivityDate == nil)
    #expect(evaluation.newEvents.isEmpty)
}

@Test("a gap day with no entry preserves but does not grow the streak")
func gapDayWithoutEntryPreservesStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let yesterday = try makeDate(year: 2026, month: 4, day: 4, calendar: calendar)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 6,
        longestStreak: 6,
        lastActivityDate: yesterday,
        lastEvaluatedDate: yesterday
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: [],
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 6)
    #expect(evaluation.newEvents.contains { $0.kind == .dailyEntry } == false)
}

@Test("a long absence with no entry resets the streak to zero")
func longAbsenceWithoutEntryResetsStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let longAgo = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 10,
        longestStreak: 12,
        lastActivityDate: longAgo,
        lastEvaluatedDate: longAgo
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: [],
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 0)
    #expect(evaluation.profile.longestStreak == 12)
}

@Test("a long absence followed by an entry restarts the streak at one")
func longAbsenceWithEntryRestartsStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let longAgo = try makeDate(year: 2026, month: 3, day: 1, calendar: calendar)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 10,
        longestStreak: 12,
        lastActivityDate: longAgo,
        lastEvaluatedDate: longAgo
    )
    let transactions = [
        Transaction(amount: 30_000, kind: .expense, category: .food, occurredAt: today),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 1)
    #expect(evaluation.profile.longestStreak == 12)
}

@Test("empty budgets do not award a budget respected reward")
func emptyBudgetsDoNotAwardReward() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(amount: 30_000, kind: .expense, category: .food, occurredAt: today),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.newEvents.contains { $0.kind == .budgetRespected } == false)
}

@Test("no spend champion tracks ten distinct no-expense days")
func noSpendChampionTracksTenDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let transactions: [Transaction] = (0..<10).compactMap { offset in
        guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
            return nil
        }
        return Transaction(amount: 100_000, kind: .income, category: .other, occurredAt: day)
    }

    let evaluation = AchievementCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        referenceDate: today,
        calendar: calendar
    )

    let champion = try #require(
        evaluation.progresses.first { $0.kind == .noSpendChampion }
    )
    #expect(champion.currentValue == 10)
    #expect(evaluation.newlyUnlocked.contains(.noSpendChampion))
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
