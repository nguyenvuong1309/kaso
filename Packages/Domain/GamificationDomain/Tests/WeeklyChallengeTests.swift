import Foundation
import Testing
import TransactionDomain
@testable import GamificationDomain

@Test("generator picks the same kind for the same week")
func generatorIsDeterministicForWeek() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let first = WeeklyChallengeGenerator.challenge(for: weekStart, calendar: calendar)
    let second = WeeklyChallengeGenerator.challenge(for: weekStart, calendar: calendar)
    #expect(first.kind == second.kind)
    #expect(first.weekStart == weekStart)
    #expect(first.target == first.kind.defaultTarget)
}

@Test("generator rotates kinds across consecutive weeks")
func generatorRotatesKinds() throws {
    let calendar = mondayFirstCalendar()
    let baseWeek = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    var kinds: Set<WeeklyChallengeKind> = []
    for offset in 0..<WeeklyChallengeKind.allCases.count {
        let weekStart = calendar.date(byAdding: .day, value: offset * 7, to: baseWeek) ?? baseWeek
        let challenge = WeeklyChallengeGenerator.challenge(for: weekStart, calendar: calendar)
        kinds.insert(challenge.kind)
    }
    #expect(kinds.count >= 3)
}

@Test("startOfWeek snaps to Monday for Vietnam-style week")
func startOfWeekSnapsToMonday() throws {
    let calendar = mondayFirstCalendar()
    let wednesday = try makeDate(year: 2026, month: 4, day: 29, calendar: calendar)
    let monday = WeeklyChallengeGenerator.startOfWeek(for: wednesday, calendar: calendar)
    let weekday = calendar.component(.weekday, from: monday)
    #expect(weekday == 2)
}

@Test("daily streak progress counts unique days within the week")
func dailyStreakProgressCountsDays() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let day1 = weekStart
    let day2 = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart
    let day3 = calendar.date(byAdding: .day, value: 2, to: weekStart) ?? weekStart
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let transactions = [
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: day1),
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: day1),
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: day2),
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: day3),
    ]

    let evaluated = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: transactions,
        rewardEvents: [],
        referenceDate: day3,
        calendar: calendar
    )

    #expect(evaluated.currentProgress == 3)
    #expect(evaluated.isCompleted == false)
}

@Test("category variety progress counts distinct categories")
func categoryVarietyProgress() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .categoryVariety, weekStart: weekStart)
    let categories: [TransactionCategory] = [.food, .transport, .housing, .entertainment]
    let transactions = categories.enumerated().map { offset, category in
        Transaction(
            amount: 100,
            kind: .expense,
            category: category,
            occurredAt: calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
        )
    }

    let evaluated = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: transactions,
        rewardEvents: [],
        referenceDate: weekStart,
        calendar: calendar
    )

    #expect(evaluated.currentProgress == 4)
    #expect(evaluated.isCompleted)
}

@Test("no spend days progress counts noSpendDay events within the week")
func noSpendDaysProgressFromEvents() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .noSpendDays, weekStart: weekStart)
    let events: [RewardEvent] = (0..<3).map { offset in
        RewardEvent(
            kind: .noSpendDay,
            earnedAt: calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
        )
    }

    let evaluated = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: [],
        rewardEvents: events,
        referenceDate: weekStart,
        calendar: calendar
    )

    #expect(evaluated.currentProgress == 3)
    #expect(evaluated.isCompleted)
}

@Test("budget keeper progress counts budgetRespected events within the week")
func budgetKeeperProgress() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .budgetKeeper, weekStart: weekStart)
    let events: [RewardEvent] = (0..<5).map { offset in
        RewardEvent(
            kind: .budgetRespected,
            earnedAt: calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
        )
    }

    let evaluated = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: [],
        rewardEvents: events,
        referenceDate: weekStart,
        calendar: calendar
    )

    #expect(evaluated.currentProgress == 5)
    #expect(evaluated.isCompleted)
}

@Test("income logger only counts income transactions")
func incomeLoggerOnlyCountsIncome() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .incomeLogger, weekStart: weekStart)

    let onlyExpenses = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: [
            Transaction(amount: 100, kind: .expense, category: .food, occurredAt: weekStart),
        ],
        rewardEvents: [],
        referenceDate: weekStart,
        calendar: calendar
    )
    #expect(onlyExpenses.currentProgress == 0)

    let withIncome = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: [
            Transaction(amount: 5_000_000, kind: .income, category: .salary, occurredAt: weekStart),
        ],
        rewardEvents: [],
        referenceDate: weekStart,
        calendar: calendar
    )
    #expect(withIncome.currentProgress == 1)
    #expect(withIncome.isCompleted)
}

@Test("evaluator excludes transactions outside the week window")
func evaluatorExcludesTransactionsOutsideWeek() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let beforeWeek = calendar.date(byAdding: .day, value: -1, to: weekStart) ?? weekStart
    let afterWeek = calendar.date(byAdding: .day, value: 8, to: weekStart) ?? weekStart
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let transactions = [
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: beforeWeek),
        Transaction(amount: 100, kind: .expense, category: .food, occurredAt: afterWeek),
    ]

    let evaluated = WeeklyChallengeEvaluator.evaluate(
        challenge: challenge,
        transactions: transactions,
        rewardEvents: [],
        referenceDate: weekStart,
        calendar: calendar
    )

    #expect(evaluated.currentProgress == 0)
}

@Test("daysRemaining decreases as the week ends")
func daysRemainingDecreases() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let challenge = WeeklyChallenge(kind: .dailyStreak, weekStart: weekStart)
    let day3 = calendar.date(byAdding: .day, value: 3, to: weekStart) ?? weekStart
    let day7 = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart

    #expect(challenge.daysRemaining(referenceDate: weekStart, calendar: calendar) == 7)
    #expect(challenge.daysRemaining(referenceDate: day3, calendar: calendar) == 4)
    #expect(challenge.daysRemaining(referenceDate: day7, calendar: calendar) == 1)
}

@Test("calculator generates a new challenge on first evaluation")
func calculatorGeneratesNewChallengeFirstTime() throws {
    let calendar = mondayFirstCalendar()
    let referenceDate = try makeDate(year: 2026, month: 4, day: 28, calendar: calendar)
    let evaluation = GamificationCalculator.evaluate(
        profile: GamificationProfile(),
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    let challenge = try #require(evaluation.profile.activeWeeklyChallenge)
    #expect(challenge.weekStart == WeeklyChallengeGenerator.startOfWeek(
        for: referenceDate,
        calendar: calendar
    ))
    #expect(evaluation.newlyCompletedWeeklyChallenge == nil)
}

@Test("calculator emits reward when challenge is just completed")
func calculatorEmitsRewardOnCompletion() throws {
    let calendar = mondayFirstCalendar()
    let weekStart = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let referenceDate = calendar.date(byAdding: .day, value: 2, to: weekStart) ?? weekStart
    let progressNeeded = WeeklyChallengeKind.categoryVariety.defaultTarget
    let categories: [TransactionCategory] = [.food, .transport, .housing, .entertainment]
    let transactions = categories.enumerated().map { offset, category in
        Transaction(
            amount: 100,
            kind: .expense,
            category: category,
            occurredAt: calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
        )
    }
    let baseProfile = GamificationProfile(
        currentStreak: 1,
        longestStreak: 1,
        activeWeeklyChallenge: WeeklyChallenge(
            kind: .categoryVariety,
            weekStart: weekStart,
            currentProgress: progressNeeded - 1
        )
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: baseProfile,
        transactions: transactions,
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    let completed = try #require(evaluation.newlyCompletedWeeklyChallenge)
    #expect(completed.kind == .categoryVariety)
    #expect(evaluation.profile.activeWeeklyChallenge?.isCompleted == true)
    #expect(evaluation.newEvents.contains { $0.kind == .weeklyChallengeCompleted })
    #expect(evaluation.profile.totalPoints >= WeeklyChallengeKind.categoryVariety.rewardPoints)
}

@Test("calculator archives stale challenge and generates new one for new week")
func calculatorArchivesStaleChallenge() throws {
    let calendar = mondayFirstCalendar()
    let lastWeekReference = try makeDate(year: 2026, month: 4, day: 20, calendar: calendar)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let lastWeekStart = WeeklyChallengeGenerator.startOfWeek(
        for: lastWeekReference,
        calendar: calendar
    )
    let expectedWeekStart = WeeklyChallengeGenerator.startOfWeek(
        for: referenceDate,
        calendar: calendar
    )
    let baseProfile = GamificationProfile(
        activeWeeklyChallenge: WeeklyChallenge(
            kind: .dailyStreak,
            weekStart: lastWeekStart,
            currentProgress: 4
        )
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: baseProfile,
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.completedWeeklyChallenges.count == 1)
    let archived = try #require(evaluation.profile.completedWeeklyChallenges.first)
    #expect(archived.weekStart == lastWeekStart)
    let active = try #require(evaluation.profile.activeWeeklyChallenge)
    #expect(active.weekStart == expectedWeekStart)
}

@Test("history is capped at 12 archived challenges")
func historyIsCapped() throws {
    let calendar = mondayFirstCalendar()
    let lastWeekStart = try makeDate(year: 2026, month: 4, day: 20, calendar: calendar)
    let referenceDate = try makeDate(year: 2026, month: 4, day: 27, calendar: calendar)
    let pastChallenges: [WeeklyChallenge] = (0..<12).map { offset in
        WeeklyChallenge(
            kind: .dailyStreak,
            weekStart: calendar.date(byAdding: .day, value: -7 * (offset + 1), to: lastWeekStart) ?? lastWeekStart
        )
    }
    let baseProfile = GamificationProfile(
        activeWeeklyChallenge: WeeklyChallenge(
            kind: .dailyStreak,
            weekStart: lastWeekStart
        ),
        completedWeeklyChallenges: pastChallenges
    )

    let evaluation = GamificationCalculator.evaluate(
        profile: baseProfile,
        transactions: [],
        budgets: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(evaluation.profile.completedWeeklyChallenges.count == GamificationProfile.weeklyChallengeHistoryLimit)
}

private func mondayFirstCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
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
