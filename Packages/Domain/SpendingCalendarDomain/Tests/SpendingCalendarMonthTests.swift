import Foundation
import Testing
@testable import SpendingCalendarDomain

@Test("SpendingCalendarMonth stores all provided fields")
func spendingCalendarMonthStoresFields() throws {
    let monthDate = try makeMonthDate(2026, 5, 1)
    let day = DailySpending(
        date: monthDate,
        total: 120_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0.1
    )
    let month = SpendingCalendarMonth(
        month: monthDate,
        days: [day],
        actualTotal: 120_000,
        forecastTotal: 60_000,
        averageDailySpending: 30_000,
        topDay: day
    )
    #expect(month.month == monthDate)
    #expect(month.days == [day])
    #expect(month.actualTotal == 120_000)
    #expect(month.forecastTotal == 60_000)
    #expect(month.averageDailySpending == 30_000)
    #expect(month.topDay == day)
}

@Test("SpendingCalendarMonth allows nil top day")
func spendingCalendarMonthAllowsNilTopDay() throws {
    let month = SpendingCalendarMonth(
        month: try makeMonthDate(2026, 5, 1),
        days: [],
        actualTotal: 0,
        forecastTotal: 0,
        averageDailySpending: 0,
        topDay: nil
    )
    #expect(month.topDay == nil)
}

@Test("SpendingCalendarMonth.empty has zeroed totals and no days")
func spendingCalendarMonthEmpty() {
    let empty = SpendingCalendarMonth.empty
    #expect(empty.days.isEmpty)
    #expect(empty.actualTotal == 0)
    #expect(empty.forecastTotal == 0)
    #expect(empty.averageDailySpending == 0)
    #expect(empty.topDay == nil)
    #expect(empty.month == Date(timeIntervalSinceReferenceDate: 0))
}

@Test("SpendingCalendarMonth equality compares all fields")
func spendingCalendarMonthEquality() throws {
    let monthDate = try makeMonthDate(2026, 5, 1)
    let a = SpendingCalendarMonth(
        month: monthDate,
        days: [],
        actualTotal: 100,
        forecastTotal: 0,
        averageDailySpending: 0,
        topDay: nil
    )
    let b = SpendingCalendarMonth(
        month: monthDate,
        days: [],
        actualTotal: 100,
        forecastTotal: 0,
        averageDailySpending: 0,
        topDay: nil
    )
    let c = SpendingCalendarMonth(
        month: monthDate,
        days: [],
        actualTotal: 200,
        forecastTotal: 0,
        averageDailySpending: 0,
        topDay: nil
    )
    #expect(a == b)
    #expect(a != c)
}

// MARK: - Helpers

private func makeMonthCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeMonthDate(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: makeMonthCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        ).date
    )
}
