import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("builds benchmark comparisons from current month spending")
func buildsBenchmarkComparisonsFromCurrentMonthSpending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let profile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .twentyToFortyMillion
    )
    let transactions = try [
        expense(amount: 4_500_000, category: .food, date: date(2026, 4, 12, calendar: calendar)),
        expense(amount: 1_000_000, category: .transport, date: date(2026, 4, 18, calendar: calendar)),
        expense(amount: 9_000_000, category: .housing, date: date(2026, 3, 1, calendar: calendar)),
    ]

    let report = AnonymousBenchmarkReporter.report(
        transactions: transactions,
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(report.totalUserExpense == 5_500_000)
    #expect(report.comparisons.count == TransactionCategory.defaultExpenseCategories.count)
    #expect(report.comparison(for: .food)?.userAmount == 4_500_000)
    #expect(report.comparison(for: .food)?.benchmarkAmount ?? 0 > 0)
    #expect(report.comparison(for: .housing)?.userAmount == 0)
}

@Test("classifies spending relative to anonymous median")
func classifiesSpendingRelativeToAnonymousMedian() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let profile = AnonymousBenchmarkProfile(
        city: .haNoi,
        ageGroup: .thirtyFiveToFortyFour,
        incomeBand: .tenToTwentyMillion
    )
    let benchmark = AnonymousBenchmarkDataset.benchmarkAmount(
        category: .food,
        profile: profile
    )

    let below = AnonymousBenchmarkReporter.report(
        transactions: [
            expense(amount: benchmark * Decimal(string: "0.70")!, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )
    let above = AnonymousBenchmarkReporter.report(
        transactions: [
            expense(amount: benchmark * Decimal(string: "1.45")!, category: .food, date: referenceDate),
        ],
        profile: profile,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(below.comparison(for: .food)?.status == .belowMedian)
    #expect(above.comparison(for: .food)?.status == .aboveMedian)
}

@Test("infers income band from monthly income")
func infersIncomeBandFromMonthlyIncome() {
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 8_000_000) == .underTenMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 15_000_000) == .tenToTwentyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 30_000_000) == .twentyToFortyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 50_000_000) == .overFortyMillion)
}

private extension AnonymousBenchmarkReport {
    func comparison(for category: TransactionCategory) -> AnonymousBenchmarkCategoryComparison? {
        comparisons.first { $0.category == category }
    }
}

private func expense(
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

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: 12
        ).date
    )
}
