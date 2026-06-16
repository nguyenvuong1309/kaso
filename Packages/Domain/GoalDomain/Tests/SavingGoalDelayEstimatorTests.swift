import Foundation
import Testing
@testable import GoalDomain

@Test("returns zero delay for non-positive overage")
func delayZeroForNonPositiveOverage() throws {
    let calendar = delayFixedCalendar()
    let goal = SavingGoal(
        name: "Goal",
        targetAmount: 30_000_000,
        currentAmount: 0,
        deadline: try delayDate(year: 2026, month: 6, day: 30)
    )

    let delay = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 0,
        goal: goal,
        asOf: try delayDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )

    #expect(delay == 0)
}

@Test("returns zero delay when goal is fully funded")
func delayZeroWhenGoalFunded() throws {
    let calendar = delayFixedCalendar()
    let goal = SavingGoal(
        name: "Funded",
        targetAmount: 10_000_000,
        currentAmount: 10_000_000,
        deadline: try delayDate(year: 2026, month: 6, day: 30)
    )

    let delay = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 1_000_000,
        goal: goal,
        asOf: try delayDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )

    #expect(delay == 0)
}

@Test("rounds fractional delayed days up")
func delayRoundsUp() throws {
    let calendar = delayFixedCalendar()
    // April..June inclusive = 3 months; remaining 9,000,000 -> monthly 3,000,000.
    let goal = SavingGoal(
        name: "Quarter",
        targetAmount: 9_000_000,
        currentAmount: 0,
        deadline: try delayDate(year: 2026, month: 6, day: 30)
    )

    // overage 100,000 * 30 / 3,000,000 = 1.0 day exactly.
    let exact = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 100_000,
        goal: goal,
        asOf: try delayDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )
    #expect(exact == 1)

    // overage 150,000 * 30 / 3,000,000 = 1.5 -> rounds up to 2.
    let rounded = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 150_000,
        goal: goal,
        asOf: try delayDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )
    #expect(rounded == 2)
}

@Test("returns at least one day for tiny positive overage")
func delayMinimumOneDay() throws {
    let calendar = delayFixedCalendar()
    let goal = SavingGoal(
        name: "Big monthly",
        targetAmount: 120_000_000,
        currentAmount: 0,
        deadline: try delayDate(year: 2026, month: 4, day: 30)
    )

    // Single month -> monthly required 120,000,000. tiny overage rounds to <1 then floored to min 1.
    let delay = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 1,
        goal: goal,
        asOf: try delayDate(year: 2026, month: 4, day: 1),
        calendar: calendar
    )

    #expect(delay == 1)
}

private func delayFixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func delayDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: delayFixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
