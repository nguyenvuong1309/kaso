import Foundation
import Testing
import TransactionDomain
@testable import SleepCorrelationDomain

// MARK: - makeDataPoints

@Test("builder ignores income and non positive expense amounts")
func builderIgnoresIncomeAndNonPositiveExpenses() throws {
    let calendar = Calendar(identifier: .gregorian)
    let day = try makeBuilderDate(year: 2026, month: 4, day: 2, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [SleepSample(date: day, hours: 7)],
        transactions: [
            Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: day),
            Transaction(amount: 0, kind: .expense, category: .food, occurredAt: day),
            Transaction(amount: 1_000_000, kind: .income, category: .salary, occurredAt: day),
        ],
        calendar: calendar
    )

    let first = try #require(points.first)
    #expect(points.count == 1)
    #expect(first.totalSpending == 50_000)
    #expect(first.transactionCount == 1)
}

@Test("builder drops sleep samples with non positive hours")
func builderDropsNonPositiveSleepHours() throws {
    let calendar = Calendar(identifier: .gregorian)
    let dayOne = try makeBuilderDate(year: 2026, month: 4, day: 1, calendar: calendar)
    let dayTwo = try makeBuilderDate(year: 2026, month: 4, day: 2, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [
            SleepSample(date: dayOne, hours: 0),
            SleepSample(date: dayTwo, hours: 7.5),
        ],
        transactions: [],
        calendar: calendar
    )

    #expect(points.count == 1)
    #expect(points.first?.sleepHours == 7.5)
}

@Test("builder buckets transactions to the start of their day")
func builderBucketsToStartOfDay() throws {
    let calendar = Calendar(identifier: .gregorian)
    let morning = try makeBuilderDate(year: 2026, month: 4, day: 5, hour: 8, calendar: calendar)
    let evening = try makeBuilderDate(year: 2026, month: 4, day: 5, hour: 22, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [SleepSample(date: morning, hours: 6.5)],
        transactions: [
            Transaction(amount: 30_000, kind: .expense, category: .food, occurredAt: morning),
            Transaction(amount: 70_000, kind: .expense, category: .transport, occurredAt: evening),
        ],
        calendar: calendar
    )

    let first = try #require(points.first)
    #expect(first.date == calendar.startOfDay(for: morning))
    #expect(first.totalSpending == 100_000)
    #expect(first.transactionCount == 2)
}

@Test("builder aggregates categories sorted by descending amount")
func builderAggregatesCategoriesSortedByAmount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let day = try makeBuilderDate(year: 2026, month: 4, day: 6, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [SleepSample(date: day, hours: 6)],
        transactions: [
            Transaction(amount: 20_000, kind: .expense, category: .food, occurredAt: day),
            Transaction(amount: 30_000, kind: .expense, category: .food, occurredAt: day),
            Transaction(amount: 90_000, kind: .expense, category: .shopping, occurredAt: day),
        ],
        calendar: calendar
    )

    let categories = try #require(points.first?.categories)
    #expect(categories.count == 2)
    #expect(categories.first?.category == .shopping)
    #expect(categories.first?.amount == 90_000)
    #expect(categories.last?.category == .food)
    #expect(categories.last?.amount == 50_000)
}

@Test("builder produces zero spending point when no transactions match a day")
func builderProducesZeroSpendingForUnmatchedDay() throws {
    let calendar = Calendar(identifier: .gregorian)
    let sleepDay = try makeBuilderDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let otherDay = try makeBuilderDate(year: 2026, month: 4, day: 20, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [SleepSample(date: sleepDay, hours: 8)],
        transactions: [
            Transaction(amount: 50_000, kind: .expense, category: .food, occurredAt: otherDay),
        ],
        calendar: calendar
    )

    let first = try #require(points.first)
    #expect(first.totalSpending == 0)
    #expect(first.transactionCount == 0)
    #expect(first.categories.isEmpty)
}

@Test("builder sorts resulting data points ascending by date")
func builderSortsByDateAscending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let early = try makeBuilderDate(year: 2026, month: 4, day: 1, calendar: calendar)
    let mid = try makeBuilderDate(year: 2026, month: 4, day: 15, calendar: calendar)
    let late = try makeBuilderDate(year: 2026, month: 4, day: 30, calendar: calendar)

    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [
            SleepSample(date: late, hours: 7),
            SleepSample(date: early, hours: 6),
            SleepSample(date: mid, hours: 8),
        ],
        transactions: [],
        calendar: calendar
    )

    #expect(points.map(\.date) == [
        calendar.startOfDay(for: early),
        calendar.startOfDay(for: mid),
        calendar.startOfDay(for: late),
    ])
}

@Test("builder returns empty array when no sleep samples")
func builderReturnsEmptyForNoSleepSamples() {
    let calendar = Calendar(identifier: .gregorian)
    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [],
        transactions: [],
        calendar: calendar
    )
    #expect(points.isEmpty)
}

// MARK: - filter

@Test("filter for all period returns all data points unchanged")
func filterAllPeriodReturnsEverything() throws {
    let calendar = Calendar(identifier: .gregorian)
    let reference = try makeBuilderDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let points = buildPoints(daysAgo: [200, 100, 5], reference: reference, calendar: calendar)

    let filtered = SleepSpendingDataBuilder.filter(
        dataPoints: points,
        period: .all,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(filtered.count == points.count)
}

@Test("filter for last thirty days keeps points within window")
func filterLastThirtyDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let reference = try makeBuilderDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let points = buildPoints(daysAgo: [40, 20, 5, 0], reference: reference, calendar: calendar)

    let filtered = SleepSpendingDataBuilder.filter(
        dataPoints: points,
        period: .lastThirtyDays,
        referenceDate: reference,
        calendar: calendar
    )

    // 40 days ago excluded; 20, 5, 0 kept.
    #expect(filtered.count == 3)
}

@Test("filter includes the boundary start date")
func filterIncludesBoundaryStartDate() throws {
    let calendar = Calendar(identifier: .gregorian)
    let reference = try makeBuilderDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let points = buildPoints(daysAgo: [30], reference: reference, calendar: calendar)

    let filtered = SleepSpendingDataBuilder.filter(
        dataPoints: points,
        period: .lastThirtyDays,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(filtered.count == 1)
}

@Test("filter excludes points after the reference date")
func filterExcludesFuturePoints() throws {
    let calendar = Calendar(identifier: .gregorian)
    let reference = try makeBuilderDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let past = try makeBuilderDate(year: 2026, month: 5, day: 25, calendar: calendar)
    let future = try makeBuilderDate(year: 2026, month: 6, day: 10, calendar: calendar)
    let points = [
        builderDataPoint(date: past),
        builderDataPoint(date: future),
    ]

    let filtered = SleepSpendingDataBuilder.filter(
        dataPoints: points,
        period: .lastThirtyDays,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(filtered.count == 1)
    #expect(filtered.first?.date == past)
}

@Test("filter for last ninety days keeps points within window")
func filterLastNinetyDays() throws {
    let calendar = Calendar(identifier: .gregorian)
    let reference = try makeBuilderDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let points = buildPoints(daysAgo: [120, 60, 10], reference: reference, calendar: calendar)

    let filtered = SleepSpendingDataBuilder.filter(
        dataPoints: points,
        period: .lastNinetyDays,
        referenceDate: reference,
        calendar: calendar
    )

    // 120 days ago excluded; 60 and 10 kept.
    #expect(filtered.count == 2)
}

// MARK: - Helpers

private func buildPoints(daysAgo: [Int], reference: Date, calendar: Calendar) -> [SleepSpendingDataPoint] {
    daysAgo.compactMap { offset in
        guard let date = calendar.date(byAdding: .day, value: -offset, to: reference) else {
            return nil
        }
        return builderDataPoint(date: date)
    }
}

private func builderDataPoint(date: Date) -> SleepSpendingDataPoint {
    SleepSpendingDataPoint(
        date: date,
        sleepHours: 7,
        totalSpending: 100_000,
        transactionCount: 1,
        categories: []
    )
}

private func makeBuilderDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
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
