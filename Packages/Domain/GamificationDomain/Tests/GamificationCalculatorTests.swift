import Foundation
import Testing
import BudgetDomain
import TransactionDomain
@testable import GamificationDomain

@Test("first daily entry seeds streak and grants entry points")
func firstDailyEntrySeedsStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 50_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 1)
    #expect(evaluation.profile.longestStreak == 1)
    #expect(evaluation.profile.totalPoints == RewardEventKind.dailyEntry.points)
    #expect(evaluation.newEvents.map(\.kind) == [.dailyEntry])
    #expect(evaluation.profile.lastActivityDate == calendar.startOfDay(for: referenceDate))
}

@Test("consecutive daily entries grow the streak")
func consecutiveEntriesGrowStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let yesterday = try makeDate(year: 2026, month: 4, day: 4, calendar: calendar)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 4,
        longestStreak: 4,
        totalPoints: 200,
        lastActivityDate: yesterday,
        lastEvaluatedDate: yesterday
    )
    let transactions = [
        Transaction(
            amount: 80_000,
            kind: .expense,
            category: .transport,
            occurredAt: today
        ),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 5)
    #expect(evaluation.profile.longestStreak == 5)
    #expect(evaluation.newEvents.contains { $0.kind == .dailyEntry })
}

@Test("missing a day resets the streak when next entry comes")
func missedDayResetsStreak() throws {
    let calendar = Calendar(identifier: .gregorian)
    let twoDaysAgo = try makeDate(year: 2026, month: 4, day: 3, calendar: calendar)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 6,
        longestStreak: 9,
        totalPoints: 320,
        lastActivityDate: twoDaysAgo,
        lastEvaluatedDate: twoDaysAgo
    )
    let transactions = [
        Transaction(
            amount: 40_000,
            kind: .expense,
            category: .food,
            occurredAt: today
        ),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.profile.currentStreak == 1)
    #expect(evaluation.profile.longestStreak == 9)
}

@Test("idempotent: re-evaluating same day does not double award points")
func reEvaluationIsIdempotent() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 30_000,
            kind: .expense,
            category: .food,
            occurredAt: today
        ),
    ]

    let firstEvaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    let secondEvaluation = GamificationCalculator.evaluate(
        profile: firstEvaluation.profile,
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(firstEvaluation.profile.totalPoints == secondEvaluation.profile.totalPoints)
    #expect(secondEvaluation.newEvents.isEmpty)
    #expect(firstEvaluation.profile.currentStreak == secondEvaluation.profile.currentStreak)
}

@Test("milestones unlock once and are stored in profile")
func milestoneUnlocksOnce() throws {
    let calendar = Calendar(identifier: .gregorian)
    let day1 = try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
    let day2 = try makeDate(year: 2026, month: 4, day: 2, calendar: calendar)
    let day3 = try makeDate(year: 2026, month: 4, day: 3, calendar: calendar)
    let day4 = try makeDate(year: 2026, month: 4, day: 4, calendar: calendar)
    var profile = GamificationProfile()

    let transactionsByDay: [(Date, Date)] = [
        (day1, day1),
        (day2, day2),
        (day3, day3),
        (day4, day4),
    ]

    var lastMilestone: RewardEventKind?
    for (day, occurredAt) in transactionsByDay {
        let evaluation = GamificationCalculator.evaluate(
            profile: profile,
            transactions: [
                Transaction(
                    amount: 25_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: occurredAt
                ),
            ],
            budgets: [],
            referenceDate: day,
            calendar: calendar
        )
        profile = evaluation.profile
        if let achieved = evaluation.achievedMilestone {
            lastMilestone = achieved
        }
    }

    #expect(profile.currentStreak == 4)
    #expect(profile.unlockedMilestones.contains(.streakMilestone3))
    #expect(lastMilestone == .streakMilestone3)
    // Đánh giá lại ở ngày 4 không cấp lại milestone 3.
    let secondPass = GamificationCalculator.evaluate(
        profile: profile,
        transactions: [
            Transaction(
                amount: 25_000,
                kind: .expense,
                category: .food,
                occurredAt: day4
            ),
        ],
        budgets: [],
        referenceDate: day4,
        calendar: calendar
    )
    #expect(secondPass.achievedMilestone == nil)
}

@Test("no-spend day grants reward when there are no expenses")
func noSpendDayGrantsReward() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 12_000_000,
            kind: .income,
            category: .salary,
            occurredAt: today
        ),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: [],
        referenceDate: today,
        calendar: calendar
    )

    #expect(evaluation.newEvents.contains { $0.kind == .dailyEntry })
    #expect(evaluation.newEvents.contains { $0.kind == .noSpendDay })
}

@Test("budget respected reward only fires when all budgets are healthy")
func budgetRespectedReward() throws {
    let calendar = Calendar(identifier: .gregorian)
    let today = try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let transactions = [
        Transaction(
            amount: 80_000,
            kind: .expense,
            category: .food,
            occurredAt: today
        ),
    ]
    let healthyBudgets = [
        Budget(category: .food, monthlyLimit: 2_000_000, spent: 100_000),
        Budget(category: .transport, monthlyLimit: 1_000_000, spent: 100_000),
    ]
    let exceededBudgets = [
        Budget(category: .food, monthlyLimit: 100_000, spent: 250_000),
    ]

    let healthyEvaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: healthyBudgets,
        referenceDate: today,
        calendar: calendar
    )
    #expect(healthyEvaluation.newEvents.contains { $0.kind == .budgetRespected })

    let exceededEvaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: transactions,
        budgets: exceededBudgets,
        referenceDate: today,
        calendar: calendar
    )
    #expect(exceededEvaluation.newEvents.contains { $0.kind == .budgetRespected } == false)
}

@Test("recent events list is capped to keep payload small")
func recentEventsAreCapped() throws {
    let calendar = Calendar(identifier: .gregorian)
    let manyEvents = (0..<60).map { offset in
        RewardEvent(
            kind: .dailyEntry,
            earnedAt: Date(timeIntervalSinceReferenceDate: TimeInterval(offset))
        )
    }
    let referenceDate = try makeDate(year: 2026, month: 4, day: 6, calendar: calendar)
    let profile = GamificationProfile(
        currentStreak: 1,
        longestStreak: 1,
        totalPoints: 0,
        lastActivityDate: try makeDate(year: 2026, month: 4, day: 5, calendar: calendar),
        lastEvaluatedDate: try makeDate(year: 2026, month: 4, day: 5, calendar: calendar),
        rewardEvents: manyEvents
    )
    let transactions = [
        Transaction(
            amount: 10_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]

    let evaluation = GamificationCalculator.evaluate(
        profile: profile,
        transactions: transactions,
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.rewardEvents.count <= 30)
    #expect(evaluation.profile.rewardEvents.first?.earnedAt == referenceDate)
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
