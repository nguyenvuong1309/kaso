import Foundation
import Testing
@testable import SpendingCalendarDomain

@Test("builder fills every day of the month with kind based on reference date")
func builderFillsEveryDay() throws {
    let reference = try date(2026, 4, 15)
    let month = try date(2026, 4, 10)
    let transactions: [SpendingCalendarTransaction] = [
        SpendingCalendarTransaction(amount: 100_000, occurredAt: try date(2026, 4, 1), label: "Cafe"),
        SpendingCalendarTransaction(amount: 250_000, occurredAt: try date(2026, 4, 12), label: "Grocery"),
    ]
    let recurring: [SpendingCalendarRecurringEvent] = [
        SpendingCalendarRecurringEvent(
            label: "Internet",
            amount: 250_000,
            firstOccurrence: try date(2026, 1, 20),
            intervalDays: 30
        ),
    ]

    let result = SpendingCalendarBuilder.build(
        month: month,
        transactions: transactions,
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: fixedCalendar()
    )

    #expect(result.days.count == 30)
    #expect(result.actualTotal == 350_000)
    #expect(result.days.first?.kind == .actual)
    let lastDay = try #require(result.days.last)
    #expect(lastDay.kind == .forecast)
}

@Test("forecast totals include recurring events after reference date")
func forecastTotalsIncludeRecurring() throws {
    let reference = try date(2026, 4, 10)
    let month = try date(2026, 4, 10)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Rent",
            amount: 8_000_000,
            firstOccurrence: try date(2026, 4, 25),
            intervalDays: 30
        ),
        SpendingCalendarRecurringEvent(
            label: "Internet",
            amount: 250_000,
            firstOccurrence: try date(2026, 4, 28),
            intervalDays: 30
        ),
    ]

    let result = SpendingCalendarBuilder.build(
        month: month,
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: fixedCalendar()
    )

    #expect(result.forecastTotal == 8_250_000)
}

@Test("top day picks the actual day with the highest total")
func topDayPicksHighestActual() throws {
    let reference = try date(2026, 4, 30)
    let month = try date(2026, 4, 15)
    let transactions = [
        SpendingCalendarTransaction(amount: 200_000, occurredAt: try date(2026, 4, 3), label: "Bun bo"),
        SpendingCalendarTransaction(amount: 1_500_000, occurredAt: try date(2026, 4, 10), label: "Sneaker"),
        SpendingCalendarTransaction(amount: 400_000, occurredAt: try date(2026, 4, 15), label: "Coffee"),
    ]

    let result = SpendingCalendarBuilder.build(
        month: month,
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: fixedCalendar()
    )

    let topDay = try #require(result.topDay)
    #expect(topDay.total == 1_500_000)
}

@Test("intensity reflects spending vs average")
func intensityReflectsAverage() {
    let day = DailySpending(
        date: Date(),
        total: 500_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0.5
    )
    let emptyDay = DailySpending(
        date: Date(),
        total: 0,
        kind: .actual,
        items: [],
        deltaFromAverage: 0
    )
    let lowDay = DailySpending(
        date: Date(),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: -0.5
    )

    #expect(day.intensity == .high)
    #expect(emptyDay.intensity == .empty)
    #expect(lowDay.intensity == .low)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        ).date
    )
}
