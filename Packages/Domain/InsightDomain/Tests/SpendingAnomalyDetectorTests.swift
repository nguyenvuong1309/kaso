import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("detects large transaction against category baseline")
func detectsLargeTransactionAgainstCategoryBaseline() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try #require(date(2026, 4, 26, calendar: calendar))
    let largeTransactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let transactions = [
        expense(50_000, .food, 2026, 1, 10, calendar),
        expense(60_000, .food, 2026, 2, 10, calendar),
        expense(55_000, .food, 2026, 3, 10, calendar),
        expense(250_000, .food, 2026, 4, 20, calendar, id: largeTransactionID),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar
    )

    #expect(anomalies.contains {
        $0.kind == .largeTransaction
            && $0.transactionID == largeTransactionID
            && $0.category == .food
    })
}

@Test("detects category spending spike against previous months")
func detectsCategorySpendingSpikeAgainstPreviousMonths() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try #require(date(2026, 4, 26, calendar: calendar))
    let transactions = [
        expense(100_000, .transport, 2026, 1, 10, calendar),
        expense(100_000, .transport, 2026, 2, 10, calendar),
        expense(100_000, .transport, 2026, 3, 10, calendar),
        expense(100_000, .transport, 2026, 4, 10, calendar),
        expense(180_000, .transport, 2026, 4, 20, calendar),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar,
        configuration: SpendingAnomalyDetectionConfiguration(minimumAmountDelta: 50_000)
    )

    #expect(anomalies.contains {
        $0.kind == .categorySpike
            && $0.category == .transport
            && $0.amount == 280_000
            && $0.baselineAmount == 100_000
    })
}

@Test("ignores income and old history")
func ignoresIncomeAndOldHistory() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try #require(date(2026, 4, 26, calendar: calendar))
    let transactions = [
        income(10_000_000, 2026, 4, 1, calendar),
        expense(500_000, .shopping, 2025, 12, 10, calendar),
        expense(120_000, .shopping, 2026, 4, 20, calendar),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar
    )

    #expect(anomalies.isEmpty)
}

@Test("requires enough historical transactions")
func requiresEnoughHistoricalTransactions() throws {
    let calendar = Calendar(identifier: .gregorian)
    let currentDate = try #require(date(2026, 4, 26, calendar: calendar))
    let transactions = [
        expense(50_000, .food, 2026, 3, 10, calendar),
        expense(250_000, .food, 2026, 4, 20, calendar),
    ]

    let anomalies = SpendingAnomalyDetector.detect(
        transactions: transactions,
        currentDate: currentDate,
        calendar: calendar
    )

    #expect(anomalies.isEmpty)
}

private func expense(
    _ amount: Decimal,
    _ category: TransactionCategory,
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ calendar: Calendar,
    id: UUID = UUID()
) -> Transaction {
    Transaction(
        id: id,
        amount: amount,
        kind: .expense,
        category: category,
        occurredAt: date(year, month, day, calendar: calendar) ?? Date()
    )
}

private func income(
    _ amount: Decimal,
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ calendar: Calendar
) -> Transaction {
    Transaction(
        amount: amount,
        kind: .income,
        category: .salary,
        occurredAt: date(year, month, day, calendar: calendar) ?? Date()
    )
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) -> Date? {
    DateComponents(calendar: calendar, year: year, month: month, day: day).date
}
