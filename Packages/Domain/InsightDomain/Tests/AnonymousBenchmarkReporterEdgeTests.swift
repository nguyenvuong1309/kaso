import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("near-median status when spending sits between the thresholds")
func benchmarkReporterNearMedianStatus() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try benchmarkDate(2026, 4, 26, calendar: calendar)
    let profile = AnonymousBenchmarkProfile(
        city: .haNoi,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .tenToTwentyMillion
    )
    let benchmark = AnonymousBenchmarkDataset.benchmarkAmount(category: .food, profile: profile)

    let report = AnonymousBenchmarkReporter.report(
        transactions: [
            benchmarkExpense(amount: benchmark, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    let comparison = try #require(report.comparisons.first { $0.category == .food })
    #expect(comparison.status == .nearMedian)
    // user == benchmark -> ratio 1 -> percentile exactly 50
    #expect(comparison.peerPercentile == 50)
    #expect(comparison.differenceAmount == 0)
}

@Test("peer percentile is clamped to the 5...95 range")
func benchmarkReporterClampsPercentile() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try benchmarkDate(2026, 4, 26, calendar: calendar)
    let profile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .tenToTwentyMillion
    )
    let benchmark = AnonymousBenchmarkDataset.benchmarkAmount(category: .food, profile: profile)

    let huge = AnonymousBenchmarkReporter.report(
        transactions: [
            benchmarkExpense(amount: benchmark * 10, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )
    let tiny = AnonymousBenchmarkReporter.report(
        transactions: [
            benchmarkExpense(amount: 1, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    let highComparison = try #require(huge.comparisons.first { $0.category == .food })
    let lowComparison = try #require(tiny.comparisons.first { $0.category == .food })
    #expect(highComparison.peerPercentile == 95)
    #expect(lowComparison.peerPercentile == 5)
}

@Test("difference ratio is the signed delta over the benchmark")
func benchmarkReporterDifferenceRatio() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try benchmarkDate(2026, 4, 26, calendar: calendar)
    let profile = AnonymousBenchmarkProfile()
    let benchmark = AnonymousBenchmarkDataset.benchmarkAmount(category: .food, profile: profile)

    let report = AnonymousBenchmarkReporter.report(
        transactions: [
            benchmarkExpense(amount: benchmark * 2, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    let comparison = try #require(report.comparisons.first { $0.category == .food })
    #expect(comparison.differenceAmount == benchmark)
    #expect(comparison.differenceRatio == 1)
}

@Test("only current-month expenses up to the reference date are counted")
func benchmarkReporterFiltersByDateAndKind() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try benchmarkDate(2026, 4, 15, calendar: calendar)
    let profile = AnonymousBenchmarkProfile()
    let transactions = try [
        benchmarkExpense(amount: 1_000_000, category: .food, date: benchmarkDate(2026, 4, 10, calendar: calendar)),
        // future within the same month -> excluded by occurredAt <= referenceDate
        benchmarkExpense(amount: 5_000_000, category: .food, date: benchmarkDate(2026, 4, 20, calendar: calendar)),
        // income -> excluded
        Transaction(amount: 9_000_000, kind: .income, category: .salary, occurredAt: benchmarkDate(2026, 4, 5, calendar: calendar)),
        // previous month -> excluded
        benchmarkExpense(amount: 2_000_000, category: .food, date: benchmarkDate(2026, 3, 10, calendar: calendar)),
    ]

    let report = AnonymousBenchmarkReporter.report(
        transactions: transactions,
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    let comparison = try #require(report.comparisons.first { $0.category == .food })
    #expect(comparison.userAmount == 1_000_000)
    #expect(report.totalUserExpense == 1_000_000)
}

@Test("overall status and percentile aggregate every category benchmark")
func benchmarkReporterOverallAggregation() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try benchmarkDate(2026, 4, 26, calendar: calendar)
    let profile = AnonymousBenchmarkProfile()

    let report = AnonymousBenchmarkReporter.report(
        transactions: [],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(report.totalUserExpense == 0)
    #expect(report.totalBenchmarkExpense > 0)
    // zero spending against a positive benchmark is well below the median
    #expect(report.overallStatus == .belowMedian)
    #expect(report.overallPeerPercentile == 5)
    // empty user + positive benchmark -> topComparisons keeps benchmark-only rows
    #expect(report.topComparisons.isEmpty == false)
}

private func benchmarkExpense(
    amount: Decimal,
    category: TransactionCategory,
    date: Date
) -> Transaction {
    Transaction(
        amount: amount,
        kind: .expense,
        category: category,
        occurredAt: date
    )
}

private func benchmarkDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
