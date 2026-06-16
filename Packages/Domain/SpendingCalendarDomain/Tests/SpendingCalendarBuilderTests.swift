import Foundation
import Testing
@testable import SpendingCalendarDomain

// MARK: - Recurring event normalization

@Test("recurring event clamps interval to at least one day")
func recurringEventClampsInterval() throws {
    let zero = SpendingCalendarRecurringEvent(
        label: "Daily",
        amount: 1_000,
        firstOccurrence: try buildDate(2026, 4, 1),
        intervalDays: 0
    )
    let negative = SpendingCalendarRecurringEvent(
        label: "Daily",
        amount: 1_000,
        firstOccurrence: try buildDate(2026, 4, 1),
        intervalDays: -5
    )
    #expect(zero.intervalDays == 1)
    #expect(negative.intervalDays == 1)
}

@Test("recurring event keeps a valid interval")
func recurringEventKeepsValidInterval() throws {
    let event = SpendingCalendarRecurringEvent(
        label: "Weekly",
        amount: 1_000,
        firstOccurrence: try buildDate(2026, 4, 1),
        intervalDays: 7
    )
    #expect(event.intervalDays == 7)
}

@Test("transaction stores all fields including category")
func transactionStoresFields() throws {
    let occurred = try buildDate(2026, 4, 5)
    let tx = SpendingCalendarTransaction(
        amount: 99_000,
        occurredAt: occurred,
        label: "Book",
        category: "Education"
    )
    #expect(tx.amount == 99_000)
    #expect(tx.occurredAt == occurred)
    #expect(tx.label == "Book")
    #expect(tx.category == "Education")
}

// MARK: - Empty / degenerate inputs

@Test("builder with no data still fills every day of the month")
func builderEmptyFillsDays() throws {
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 2, 1),
        transactions: [],
        recurringEvents: [],
        referenceDate: try buildDate(2026, 2, 15),
        calendar: buildCalendar()
    )
    // February 2026 is not a leap year -> 28 days.
    #expect(result.days.count == 28)
    #expect(result.actualTotal == 0)
    #expect(result.forecastTotal == 0)
    #expect(result.averageDailySpending == 0)
    #expect(result.topDay == nil)
}

@Test("builder month start is normalized to the first of the month")
func builderNormalizesMonthStart() throws {
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 7, 18),
        transactions: [],
        recurringEvents: [],
        referenceDate: try buildDate(2026, 7, 18),
        calendar: buildCalendar()
    )
    #expect(result.month == (try buildDate(2026, 7, 1)))
    #expect(result.days.first?.date == (try buildDate(2026, 7, 1)))
}

@Test("builder leap year February has 29 days")
func builderLeapYearFebruary() throws {
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2024, 2, 1),
        transactions: [],
        recurringEvents: [],
        referenceDate: try buildDate(2024, 2, 28),
        calendar: buildCalendar()
    )
    #expect(result.days.count == 29)
}

// MARK: - Average and delta

@Test("average only counts past days that have transactions")
func averageCountsOnlyActiveDays() throws {
    let reference = try buildDate(2026, 4, 30)
    let transactions = [
        SpendingCalendarTransaction(amount: 100_000, occurredAt: try buildDate(2026, 4, 1), label: "A"),
        SpendingCalendarTransaction(amount: 300_000, occurredAt: try buildDate(2026, 4, 2), label: "B"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    // 400_000 over 2 active days -> 200_000 average.
    #expect(result.actualTotal == 400_000)
    #expect(result.averageDailySpending == 200_000)
}

@Test("delta from average is computed per active day")
func deltaFromAverageComputed() throws {
    let reference = try buildDate(2026, 4, 30)
    let transactions = [
        SpendingCalendarTransaction(amount: 100_000, occurredAt: try buildDate(2026, 4, 1), label: "A"),
        SpendingCalendarTransaction(amount: 300_000, occurredAt: try buildDate(2026, 4, 2), label: "B"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let day1 = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 1)) })
    let day2 = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 2)) })
    // average = 200_000. day1 = (100k-200k)/200k = -0.5 ; day2 = (300k-200k)/200k = 0.5
    #expect(abs(day1.deltaFromAverage - (-0.5)) < 0.0001)
    #expect(abs(day2.deltaFromAverage - 0.5) < 0.0001)
}

@Test("delta is zero for empty days when average is positive")
func deltaZeroForEmptyDays() throws {
    let reference = try buildDate(2026, 4, 30)
    let transactions = [
        SpendingCalendarTransaction(amount: 200_000, occurredAt: try buildDate(2026, 4, 2), label: "B"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let emptyDay = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 1)) })
    // average = 200_000, total 0 -> delta = (0 - 200k)/200k = -1.0
    #expect(abs(emptyDay.deltaFromAverage - (-1.0)) < 0.0001)
}

@Test("delta is zero when average is zero")
func deltaZeroWhenNoAverage() throws {
    let reference = try buildDate(2026, 4, 30)
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    for day in result.days where day.kind == .actual {
        #expect(day.deltaFromAverage == 0)
    }
}

// MARK: - Same-day aggregation & items

@Test("multiple transactions on same day are summed and listed as items")
func sameDayTransactionsAggregated() throws {
    let reference = try buildDate(2026, 4, 30)
    let day = try buildDate(2026, 4, 10)
    let transactions = [
        SpendingCalendarTransaction(amount: 50_000, occurredAt: day, label: "Coffee", category: "Food"),
        SpendingCalendarTransaction(amount: 70_000, occurredAt: day, label: "Lunch", category: "Food"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let target = try #require(result.days.first { $0.date == day })
    #expect(target.total == 120_000)
    #expect(target.items.count == 2)
    #expect(target.items.map(\.label).sorted() == ["Coffee", "Lunch"])
    #expect(target.items.allSatisfy { $0.category == "Food" })
}

@Test("transactions are grouped by start of day regardless of time")
func transactionsGroupedByStartOfDay() throws {
    let reference = try buildDate(2026, 4, 30)
    let transactions = [
        SpendingCalendarTransaction(
            amount: 10_000,
            occurredAt: try buildDate(2026, 4, 10, hour: 1),
            label: "Early"
        ),
        SpendingCalendarTransaction(
            amount: 20_000,
            occurredAt: try buildDate(2026, 4, 10, hour: 23),
            label: "Late"
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let target = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 10)) })
    #expect(target.total == 30_000)
    #expect(target.items.count == 2)
}

// MARK: - Reference date boundary

@Test("reference day itself is treated as actual")
func referenceDayIsActual() throws {
    let reference = try buildDate(2026, 4, 15)
    let transactions = [
        SpendingCalendarTransaction(amount: 60_000, occurredAt: try buildDate(2026, 4, 15), label: "Today"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let today = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 15)) })
    #expect(today.kind == .actual)
    #expect(today.total == 60_000)
    #expect(result.actualTotal == 60_000)
}

@Test("day after reference is treated as forecast")
func dayAfterReferenceIsForecast() throws {
    let reference = try buildDate(2026, 4, 15)
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let nextDay = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 16)) })
    #expect(nextDay.kind == .forecast)
}

@Test("transactions after reference do not count toward actual total")
func transactionsAfterReferenceIgnoredForActual() throws {
    let reference = try buildDate(2026, 4, 10)
    let transactions = [
        SpendingCalendarTransaction(amount: 100_000, occurredAt: try buildDate(2026, 4, 5), label: "Past"),
        SpendingCalendarTransaction(amount: 500_000, occurredAt: try buildDate(2026, 4, 20), label: "Future"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    #expect(result.actualTotal == 100_000)
    // The future-dated transaction lands on a forecast day, so it is not surfaced as actual items.
    let futureDay = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 20)) })
    #expect(futureDay.kind == .forecast)
    #expect(futureDay.total == 0)
}

// MARK: - Forecast / recurring

@Test("recurring event repeats across the month at its interval")
func recurringRepeatsAcrossMonth() throws {
    let reference = try buildDate(2026, 4, 1)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Coffee",
            amount: 30_000,
            firstOccurrence: try buildDate(2026, 4, 2),
            intervalDays: 7
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: buildCalendar()
    )
    // Occurrences on Apr 2, 9, 16, 23, 30 -> 5 occurrences * 30k = 150k.
    #expect(result.forecastTotal == 150_000)
    let occurrenceDates = result.days
        .filter { !$0.items.isEmpty }
        .map(\.date)
    #expect(occurrenceDates.count == 5)
}

@Test("recurring event with first occurrence before the month rolls forward")
func recurringRollsForwardIntoMonth() throws {
    let reference = try buildDate(2026, 4, 1)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Subscription",
            amount: 100_000,
            firstOccurrence: try buildDate(2026, 1, 5),
            intervalDays: 30
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: buildCalendar()
    )
    // Jan 5 + 30 = Feb 4 + 30 = Mar 6 + 30 = Apr 5 (in month), next Apr 5 + 30 = May 5 (out).
    #expect(result.forecastTotal == 100_000)
    let target = try #require(result.days.first { $0.date == (try buildDate(2026, 4, 5)) })
    #expect(target.kind == .forecast)
    #expect(target.total == 100_000)
    #expect(target.items.first?.label == "Subscription")
}

@Test("recurring event entirely in the past contributes no forecast")
func recurringEntirelyInPastNoForecast() throws {
    let reference = try buildDate(2026, 4, 30)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "OldBill",
            amount: 200_000,
            firstOccurrence: try buildDate(2026, 4, 5),
            intervalDays: 1
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: buildCalendar()
    )
    // All occurrences fall on past-or-today days, which use actual (not forecast) path.
    #expect(result.forecastTotal == 0)
}

@Test("recurring event occurring entirely after the month is excluded")
func recurringAfterMonthExcluded() throws {
    let reference = try buildDate(2026, 4, 1)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Later",
            amount: 500_000,
            firstOccurrence: try buildDate(2026, 6, 1),
            intervalDays: 30
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: buildCalendar()
    )
    #expect(result.forecastTotal == 0)
    #expect(result.days.allSatisfy { $0.items.isEmpty })
}

// MARK: - Top day

@Test("top day is nil when there are no actual spending days")
func topDayNilWhenNoActuals() throws {
    let reference = try buildDate(2026, 4, 1)
    let recurring = [
        SpendingCalendarRecurringEvent(
            label: "Rent",
            amount: 5_000_000,
            firstOccurrence: try buildDate(2026, 4, 10),
            intervalDays: 30
        ),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: [],
        recurringEvents: recurring,
        referenceDate: reference,
        calendar: buildCalendar()
    )
    // Forecast days are excluded from top day selection.
    #expect(result.topDay == nil)
}

@Test("top day ignores zero-total actual days")
func topDayIgnoresZeroDays() throws {
    let reference = try buildDate(2026, 4, 30)
    let transactions = [
        SpendingCalendarTransaction(amount: 80_000, occurredAt: try buildDate(2026, 4, 3), label: "Only"),
    ]
    let result = SpendingCalendarBuilder.build(
        month: try buildDate(2026, 4, 1),
        transactions: transactions,
        recurringEvents: [],
        referenceDate: reference,
        calendar: buildCalendar()
    )
    let top = try #require(result.topDay)
    #expect(top.date == (try buildDate(2026, 4, 3)))
    #expect(top.total == 80_000)
}

// MARK: - Helpers

private func buildCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func buildDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) throws -> Date {
    try #require(
        DateComponents(
            calendar: buildCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
