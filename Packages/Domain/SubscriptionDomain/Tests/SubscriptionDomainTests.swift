import Foundation
import Testing
import TransactionDomain
@testable import SubscriptionDomain

@Test("detects monthly subscription from note")
func detectsMonthlySubscriptionFromNote() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        try expense(amount: 260_000, occurredAt: date(2026, 1, 1, calendar: calendar), note: "Netflix Premium Jan"),
        try expense(amount: 260_000, occurredAt: date(2026, 2, 1, calendar: calendar), note: "Netflix Premium Feb"),
        try expense(amount: 260_000, occurredAt: date(2026, 3, 1, calendar: calendar), note: "Netflix Premium Mar"),
    ]

    let result = SubscriptionDetector().detect(
        from: transactions,
        referenceDate: try date(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )
    let subscription = try #require(result.subscriptions.first)
    let expectedNextBillingDate = try date(2026, 5, 1, calendar: calendar)

    #expect(result.subscriptions.count == 1)
    #expect(subscription.name == "Netflix")
    #expect(subscription.merchant.source == .note)
    #expect(subscription.interval == .monthly)
    #expect(subscription.nextBillingDate == expectedNextBillingDate)
    #expect(subscription.monthlyAmount == 260_000)
    #expect(result.monthlyTotal == 260_000)
}

@Test("detects weekly subscription and monthly equivalent")
func detectsWeeklySubscriptionAndMonthlyEquivalent() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        try expense(amount: 30_000, occurredAt: date(2026, 1, 3, calendar: calendar), note: "Yoga class weekly"),
        try expense(amount: 30_000, occurredAt: date(2026, 1, 10, calendar: calendar), note: "Yoga class weekly"),
        try expense(amount: 30_000, occurredAt: date(2026, 1, 17, calendar: calendar), note: "Yoga class weekly"),
    ]

    let result = SubscriptionDetector().detect(
        from: transactions,
        referenceDate: try date(2026, 1, 18, calendar: calendar),
        calendar: calendar
    )
    let subscription = try #require(result.subscriptions.first)
    let expectedNextBillingDate = try date(2026, 1, 24, calendar: calendar)

    #expect(result.subscriptions.count == 1)
    #expect(subscription.name == "Yoga class")
    #expect(subscription.interval == .weekly)
    #expect(subscription.nextBillingDate == expectedNextBillingDate)
    #expect(subscription.monthlyAmount == 130_000)
    #expect(result.monthlyTotal == 130_000)
}

@Test("detects yearly subscription and prorates monthly total")
func detectsYearlySubscriptionAndProratesMonthlyTotal() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        try expense(
            amount: 1_200_000,
            occurredAt: date(2024, 4, 20, calendar: calendar),
            note: "iCloud annual subscription"
        ),
        try expense(
            amount: 1_200_000,
            occurredAt: date(2025, 4, 20, calendar: calendar),
            note: "iCloud annual subscription"
        ),
    ]

    let result = SubscriptionDetector().detect(
        from: transactions,
        referenceDate: try date(2025, 4, 26, calendar: calendar),
        calendar: calendar
    )
    let subscription = try #require(result.subscriptions.first)
    let expectedNextBillingDate = try date(2026, 4, 20, calendar: calendar)

    #expect(result.subscriptions.count == 1)
    #expect(subscription.name == "iCloud")
    #expect(subscription.interval == .yearly)
    #expect(subscription.nextBillingDate == expectedNextBillingDate)
    #expect(subscription.monthlyAmount == 100_000)
    #expect(result.monthlyTotal == 100_000)
}

@Test("falls back to category when note is missing")
func fallsBackToCategoryWhenNoteIsMissing() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        try expense(amount: 5_000_000, category: .housing, occurredAt: date(2026, 1, 5, calendar: calendar)),
        try expense(amount: 5_000_000, category: .housing, occurredAt: date(2026, 2, 5, calendar: calendar)),
        try expense(amount: 5_000_000, category: .housing, occurredAt: date(2026, 3, 5, calendar: calendar)),
    ]

    let result = SubscriptionDetector().detect(
        from: transactions,
        referenceDate: try date(2026, 3, 10, calendar: calendar),
        calendar: calendar
    )
    let subscription = try #require(result.subscriptions.first)
    let expectedNextBillingDate = try date(2026, 4, 5, calendar: calendar)

    #expect(result.subscriptions.count == 1)
    #expect(subscription.name == TransactionCategory.housing.nameKey)
    #expect(subscription.merchant.source == .category)
    #expect(subscription.interval == .monthly)
    #expect(subscription.nextBillingDate == expectedNextBillingDate)
    #expect(subscription.monthlyAmount == 5_000_000)
}

@Test("ignores income and irregular expenses")
func ignoresIncomeAndIrregularExpenses() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = [
        Transaction(
            amount: 260_000,
            kind: .income,
            category: .salary,
            occurredAt: try date(2026, 1, 1, calendar: calendar),
            note: "Netflix Premium Jan"
        ),
        try expense(amount: 120_000, occurredAt: date(2026, 1, 5, calendar: calendar), note: "Random Store"),
        try expense(amount: 120_000, occurredAt: date(2026, 1, 20, calendar: calendar), note: "Random Store"),
        try expense(amount: 120_000, occurredAt: date(2026, 2, 20, calendar: calendar), note: "Random Store"),
    ]

    let result = SubscriptionDetector().detect(
        from: transactions,
        referenceDate: try date(2026, 2, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(result.subscriptions.isEmpty)
    #expect(result.monthlyTotal == 0)
}

private func expense(
    amount: Decimal,
    category: TransactionCategory = .entertainment,
    occurredAt: Date,
    note: String? = nil
) -> Transaction {
    Transaction(
        amount: amount,
        kind: .expense,
        category: category,
        occurredAt: occurredAt,
        note: note
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
            day: day
        ).date
    )
}
