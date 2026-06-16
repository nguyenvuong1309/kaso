import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("zero history-month configuration produces no anomalies")
func anomalyDetectorZeroHistoryConfiguration() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try anomalyDate(2026, 4, 26, calendar: calendar)
    let transactions = try [
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 1, 10, calendar: calendar)),
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 2, 10, calendar: calendar)),
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 3, 10, calendar: calendar)),
        anomalyExpense(500_000, .food, date: anomalyDate(2026, 4, 20, calendar: calendar)),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar,
        configuration: SpendingAnomalyDetectionConfiguration(historyMonthCount: 0)
    )

    #expect(anomalies.isEmpty)
}

@Test("a large multiplier without enough absolute delta is ignored")
func anomalyDetectorRequiresMinimumDelta() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try anomalyDate(2026, 4, 26, calendar: calendar)
    // baseline ~10,000, current 30,000: 3x ratio but only 20,000 above baseline.
    let transactions = try [
        anomalyExpense(10_000, .food, date: anomalyDate(2026, 1, 10, calendar: calendar)),
        anomalyExpense(10_000, .food, date: anomalyDate(2026, 2, 10, calendar: calendar)),
        anomalyExpense(10_000, .food, date: anomalyDate(2026, 3, 10, calendar: calendar)),
        anomalyExpense(30_000, .food, date: anomalyDate(2026, 4, 20, calendar: calendar)),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar
    )

    // default minimumAmountDelta is 100,000, so the 20,000 delta keeps it out
    #expect(anomalies.isEmpty)
}

@Test("anomalies are sorted by most recent then largest amount")
func anomalyDetectorSortsByDateThenAmount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try anomalyDate(2026, 4, 28, calendar: calendar)
    let firstID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let secondID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let transactions = try [
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 1, 10, calendar: calendar)),
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 2, 10, calendar: calendar)),
        anomalyExpense(50_000, .food, date: anomalyDate(2026, 3, 10, calendar: calendar)),
        anomalyExpense(50_000, .transport, date: anomalyDate(2026, 1, 11, calendar: calendar)),
        anomalyExpense(50_000, .transport, date: anomalyDate(2026, 2, 11, calendar: calendar)),
        anomalyExpense(50_000, .transport, date: anomalyDate(2026, 3, 11, calendar: calendar)),
        anomalyExpense(400_000, .food, date: anomalyDate(2026, 4, 12, calendar: calendar), id: firstID),
        anomalyExpense(500_000, .transport, date: anomalyDate(2026, 4, 25, calendar: calendar), id: secondID),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar
    )

    let largeTransactions = anomalies.filter { $0.kind == .largeTransaction }
    #expect(largeTransactions.count == 2)
    // the April 25 transaction is more recent and should sort first
    #expect(largeTransactions.first?.transactionID == secondID)
}

@Test("category spike requires a full set of historical months")
func anomalyDetectorRequiresHistoricalMonths() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try anomalyDate(2026, 4, 26, calendar: calendar)
    // Only two historical months for the spike check (needs 3 by default).
    let transactions = try [
        anomalyExpense(100_000, .transport, date: anomalyDate(2026, 2, 10, calendar: calendar)),
        anomalyExpense(100_000, .transport, date: anomalyDate(2026, 3, 10, calendar: calendar)),
        anomalyExpense(100_000, .transport, date: anomalyDate(2026, 4, 5, calendar: calendar)),
        anomalyExpense(180_000, .transport, date: anomalyDate(2026, 4, 20, calendar: calendar)),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar,
        configuration: SpendingAnomalyDetectionConfiguration(minimumAmountDelta: 50_000)
    )

    #expect(anomalies.contains { $0.kind == .categorySpike } == false)
}

@Test("configuration uses documented default thresholds")
func anomalyConfigurationDefaults() {
    let configuration = SpendingAnomalyDetectionConfiguration()
    #expect(configuration.historyMonthCount == 3)
    #expect(configuration.minimumHistoricalTransactionCount == 3)
    #expect(configuration.largeTransactionMultiplier == 2)
    #expect(configuration.categorySpikeMultiplier == (Decimal(string: "1.4") ?? 1.4))
    #expect(configuration.minimumAmountDelta == 100_000)
}

private func anomalyExpense(
    _ amount: Decimal,
    _ category: TransactionCategory,
    date: Date,
    id: UUID = UUID()
) -> Transaction {
    Transaction(id: id, amount: amount, kind: .expense, category: category, occurredAt: date)
}

private func anomalyDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
