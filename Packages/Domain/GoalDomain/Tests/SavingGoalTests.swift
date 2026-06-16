import Foundation
import Testing
@testable import GoalDomain

@Test("reports notStarted when no progress and deadline in future")
func goalStatusNotStarted() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "New car",
        targetAmount: 50_000_000,
        currentAmount: 0,
        deadline: try goalDate(year: 2026, month: 12, day: 31)
    )

    #expect(goal.status(on: try goalDate(year: 2026, month: 4, day: 1), calendar: calendar) == .notStarted)
}

@Test("reports notStarted when current amount is negative")
func goalStatusNotStartedNegative() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Adjusted goal",
        targetAmount: 50_000_000,
        currentAmount: -100,
        deadline: try goalDate(year: 2026, month: 12, day: 31)
    )

    #expect(goal.status(on: try goalDate(year: 2026, month: 4, day: 1), calendar: calendar) == .notStarted)
}

@Test("reports inProgress with partial funding before deadline")
func goalStatusInProgress() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Vacation",
        targetAmount: 20_000_000,
        currentAmount: 5_000_000,
        deadline: try goalDate(year: 2026, month: 12, day: 31)
    )

    #expect(goal.status(on: try goalDate(year: 2026, month: 4, day: 1), calendar: calendar) == .inProgress)
}

@Test("treats deadline day itself as not overdue")
func goalStatusOnDeadlineDayNotOverdue() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Tax payment",
        targetAmount: 20_000_000,
        currentAmount: 5_000_000,
        deadline: try goalDate(year: 2026, month: 4, day: 30)
    )

    #expect(goal.status(on: try goalDate(year: 2026, month: 4, day: 30), calendar: calendar) == .inProgress)
}

@Test("reports overdue when deadline day has passed and not completed")
func goalStatusOverdue() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Late goal",
        targetAmount: 20_000_000,
        currentAmount: 5_000_000,
        deadline: try goalDate(year: 2026, month: 4, day: 30)
    )

    #expect(goal.status(on: try goalDate(year: 2026, month: 5, day: 1), calendar: calendar) == .overdue)
}

@Test("derives progress computed property from amounts")
func goalProgressComputedProperty() throws {
    let goal = SavingGoal(
        name: "Fund",
        targetAmount: 10_000_000,
        currentAmount: 4_000_000,
        deadline: try goalDate(year: 2026, month: 12, day: 31)
    )

    #expect(goal.progress == SavingGoalProgress(currentAmount: 4_000_000, targetAmount: 10_000_000))
    #expect(goal.progress.remainingAmount == 6_000_000)
}

@Test("monthly required saving is zero when already funded")
func goalMonthlyRequiredZeroWhenFunded() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Funded",
        targetAmount: 10_000_000,
        currentAmount: 10_000_000,
        deadline: try goalDate(year: 2026, month: 12, day: 31)
    )

    #expect(goal.monthlyRequiredSaving(asOf: try goalDate(year: 2026, month: 4, day: 1), calendar: calendar) == 0)
}

@Test("monthly required saving spreads over inclusive month range")
func goalMonthlyRequiredInclusiveRange() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "Quarter goal",
        targetAmount: 9_000_000,
        currentAmount: 0,
        deadline: try goalDate(year: 2026, month: 6, day: 30)
    )

    // April..June inclusive = 3 months.
    let required = goal.monthlyRequiredSaving(
        asOf: try goalDate(year: 2026, month: 4, day: 15),
        calendar: calendar
    )

    #expect(required == 3_000_000)
}

@Test("monthly required saving uses single month when deadline within current month")
func goalMonthlyRequiredSameMonth() throws {
    let calendar = goalFixedCalendar()
    let goal = SavingGoal(
        name: "This month",
        targetAmount: 4_000_000,
        currentAmount: 1_000_000,
        deadline: try goalDate(year: 2026, month: 4, day: 28)
    )

    let required = goal.monthlyRequiredSaving(
        asOf: try goalDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )

    #expect(required == 3_000_000)
}

@Test("round-trips saving goal through Codable")
func goalCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA"))
    let goal = SavingGoal(
        id: id,
        name: "Roundtrip",
        targetAmount: 7_500_000,
        currentAmount: 2_500_000,
        deadline: try goalDate(year: 2027, month: 1, day: 1),
        createdAt: try goalDate(year: 2026, month: 1, day: 1),
        imageIdentifier: "img-1"
    )

    let data = try JSONEncoder().encode(goal)
    let decoded = try JSONDecoder().decode(SavingGoal.self, from: data)

    #expect(decoded == goal)
}

@Test("defaults current amount to zero and image identifier to nil")
func goalDefaultInitValues() throws {
    let goal = SavingGoal(
        name: "Defaults",
        targetAmount: 1_000_000,
        deadline: try goalDate(year: 2027, month: 1, day: 1)
    )

    #expect(goal.currentAmount == 0)
    #expect(goal.imageIdentifier == nil)
}

private func goalFixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func goalDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: goalFixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
