import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("invalid configuration returns the empty analysis")
func analyzerEmptyForInvalidConfiguration() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try analyzerDate(2026, 4, 26, hour: 12, calendar: calendar)
    let transactions = [
        analyzerExpense(amount: 500_000, date: referenceDate),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(lookbackMonthCount: 0)
    )

    #expect(analysis.isEmpty)
    #expect(analysis.totalExpense == 0)
    #expect(analysis.transactionCount == 0)
}

@Test("fewer transactions than the minimum returns counts without patterns")
func analyzerBelowMinimumTransactionCount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try analyzerDate(2026, 4, 26, hour: 12, calendar: calendar)
    let transactions = try [
        analyzerExpense(amount: 100_000, date: analyzerDate(2026, 4, 10, hour: 21, calendar: calendar)),
        analyzerExpense(amount: 200_000, date: analyzerDate(2026, 4, 11, hour: 21, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(minimumTransactionCount: 5)
    )

    #expect(analysis.transactionCount == 2)
    #expect(analysis.totalExpense == 300_000)
    #expect(analysis.peakWeekdays.isEmpty)
    #expect(analysis.peakHours.isEmpty)
    #expect(analysis.eveningSpike == nil)
}

@Test("evening spike is suppressed when its share is under the threshold")
func analyzerNoEveningSpikeBelowThreshold() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try analyzerDate(2026, 4, 26, hour: 12, calendar: calendar)
    // Only one small evening transaction out of mostly daytime spend.
    let transactions = try [
        analyzerExpense(amount: 200_000, date: analyzerDate(2026, 4, 20, hour: 21, calendar: calendar)),
        analyzerExpense(amount: 1_000_000, date: analyzerDate(2026, 4, 6, hour: 9, calendar: calendar)),
        analyzerExpense(amount: 1_000_000, date: analyzerDate(2026, 4, 7, hour: 10, calendar: calendar)),
        analyzerExpense(amount: 1_000_000, date: analyzerDate(2026, 4, 8, hour: 11, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(minimumTransactionCount: 4)
    )

    // evening share ~6% < default 30% threshold
    #expect(analysis.eveningSpike == nil)
    #expect(analysis.peakHours.isEmpty == false)
}

@Test("top counts cap the number of weekday and hour patterns")
func analyzerLimitsTopCounts() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try analyzerDate(2026, 4, 26, hour: 12, calendar: calendar)
    let transactions = try [
        analyzerExpense(amount: 500_000, date: analyzerDate(2026, 4, 6, hour: 9, calendar: calendar)),
        analyzerExpense(amount: 400_000, date: analyzerDate(2026, 4, 7, hour: 10, calendar: calendar)),
        analyzerExpense(amount: 300_000, date: analyzerDate(2026, 4, 8, hour: 11, calendar: calendar)),
        analyzerExpense(amount: 200_000, date: analyzerDate(2026, 4, 9, hour: 12, calendar: calendar)),
        analyzerExpense(amount: 100_000, date: analyzerDate(2026, 4, 10, hour: 13, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(
            minimumTransactionCount: 5,
            topWeekdayCount: 3,
            topHourCount: 2
        )
    )

    #expect(analysis.peakWeekdays.count == 3)
    #expect(analysis.peakHours.count == 2)
    // highest amount first
    #expect(analysis.peakHours.first?.hour == 9)
    #expect(analysis.peakHours.first?.amount == 500_000)
}

@Test("shareOfTotal sums and stays proportional to total expense")
func analyzerShareOfTotal() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try analyzerDate(2026, 4, 26, hour: 12, calendar: calendar)
    let transactions = try [
        analyzerExpense(amount: 600_000, date: analyzerDate(2026, 4, 6, hour: 9, calendar: calendar)),
        analyzerExpense(amount: 600_000, date: analyzerDate(2026, 4, 6, hour: 9, calendar: calendar)),
        analyzerExpense(amount: 300_000, date: analyzerDate(2026, 4, 7, hour: 10, calendar: calendar)),
        analyzerExpense(amount: 300_000, date: analyzerDate(2026, 4, 8, hour: 11, calendar: calendar)),
        analyzerExpense(amount: 200_000, date: analyzerDate(2026, 4, 9, hour: 12, calendar: calendar)),
    ]

    let analysis = TimeSpendingAnalyzer.analyze(
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar,
        configuration: TimeSpendingAnalysisConfiguration(minimumTransactionCount: 5, topHourCount: 1)
    )

    #expect(analysis.totalExpense == 2_000_000)
    let topHour = try #require(analysis.peakHours.first)
    #expect(topHour.hour == 9)
    #expect(topHour.amount == 1_200_000)
    #expect(topHour.transactionCount == 2)
    // 1,200,000 / 2,000,000 = 0.6
    #expect(topHour.shareOfTotal == Decimal(string: "0.6"))
}

private func analyzerExpense(amount: Decimal, date: Date) -> Transaction {
    Transaction(amount: amount, kind: .expense, category: .food, occurredAt: date)
}

private func analyzerDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    hour: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: hour).date
    )
}
