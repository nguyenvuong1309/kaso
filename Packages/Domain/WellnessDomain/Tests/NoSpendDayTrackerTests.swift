import Foundation
import Testing
import TransactionDomain
@testable import WellnessDomain

@Test("income-only days count as no-spend days")
func incomeOnlyDaysCountAsNoSpendDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 20_000_000,
            kind: .income,
            category: .salary,
            occurredAt: try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        ),
        Transaction(
            amount: 50_000,
            kind: .expense,
            category: .food,
            occurredAt: try makeDate(year: 2026, month: 4, day: 2, calendar: calendar)
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 3, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.noSpendDaysInMonth == 2)
    #expect(summary.currentStreak == 1)
    #expect(summary.longestStreak == 1)
    #expect(summary.days.map(\.isNoSpendDay) == [true, false, true])
}

@Test("current streak walks backward from reference day")
func currentStreakWalksBackwardFromReferenceDay() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 80_000,
            kind: .expense,
            category: .transport,
            occurredAt: try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        ),
        Transaction(
            amount: 120_000,
            kind: .expense,
            category: .shopping,
            occurredAt: try makeDate(year: 2026, month: 4, day: 5, calendar: calendar)
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 4, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.noSpendDaysInMonth == 3)
    #expect(summary.currentStreak == 3)
    #expect(summary.longestStreak == 3)
}

@Test("current streak is zero when reference day has an expense")
func currentStreakIsZeroWhenReferenceDayHasExpense() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 40_000,
            kind: .expense,
            category: .food,
            occurredAt: try makeDate(year: 2026, month: 4, day: 3, calendar: calendar)
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 3, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.noSpendDaysInMonth == 2)
    #expect(summary.currentStreak == 0)
    #expect(summary.longestStreak == 2)
}

@Test("longest streak spans only consecutive no-spend days")
func longestStreakSpansOnlyConsecutiveNoSpendDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 30_000,
            kind: .expense,
            category: .food,
            occurredAt: try makeDate(year: 2026, month: 4, day: 2, calendar: calendar)
        ),
        Transaction(
            amount: 70_000,
            kind: .expense,
            category: .entertainment,
            occurredAt: try makeDate(year: 2026, month: 4, day: 6, calendar: calendar)
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 8, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.noSpendDaysInMonth == 6)
    #expect(summary.currentStreak == 2)
    #expect(summary.longestStreak == 3)
}

@Test("estimates savings and tracks streak milestones")
func estimatesSavingsAndTracksStreakMilestones() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 100_000,
            kind: .expense,
            category: .food,
            occurredAt: try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 4, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.currentStreak == 3)
    #expect(summary.noSpendDaysInMonth == 3)
    #expect(summary.estimatedSavings == 300_000)
    #expect(summary.achievedMilestone == .threeDays)
    #expect(summary.nextMilestone == .sevenDays)
}

@Test("day bucketing uses the supplied calendar time zone")
func dayBucketingUsesSuppliedCalendarTimeZone() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
    var utcCalendar = Calendar(identifier: .gregorian)
    utcCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let lateUtcExpense = try makeDate(
        year: 2026,
        month: 4,
        day: 1,
        hour: 17,
        minute: 30,
        calendar: utcCalendar
    )
    let transactions = [
        Transaction(
            amount: 90_000,
            kind: .expense,
            category: .food,
            occurredAt: lateUtcExpense
        ),
    ]

    let summary = try NoSpendDayTracker.monthSummary(
        from: transactions,
        containing: makeDate(year: 2026, month: 4, day: 2, calendar: calendar),
        calendar: calendar
    )

    #expect(summary.noSpendDaysInMonth == 1)
    #expect(summary.days.map(\.isNoSpendDay) == [true, false])
    #expect(summary.currentStreak == 0)
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    minute: Int = 0,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date
    )
}
