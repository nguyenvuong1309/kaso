import Foundation
import Testing
@testable import TransactionDomain

@Test("validates positive transaction draft")
func validatesPositiveTransactionDraft() throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let draft = TransactionDraft(
        amount: 125_000,
        kind: .expense,
        category: .food,
        occurredAt: date
    )

    let transaction = try draft.validated()

    #expect(transaction.amount == 125_000)
    #expect(transaction.kind == .expense)
    #expect(transaction.category == .food)
}

@Test("rejects zero amount transaction draft")
func rejectsZeroAmountTransactionDraft() throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let draft = TransactionDraft(
        amount: 0,
        kind: .expense,
        category: .food,
        occurredAt: date
    )

    #expect(throws: TransactionValidationError.amountMustBePositive) {
        try draft.validated()
    }
}

@Test("calculates current month summary")
func calculatesCurrentMonthSummary() throws {
    let calendar = Calendar(identifier: .gregorian)
    let targetDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let previousMonthDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 3, day: 26).date
    )
    let transactions = [
        Transaction(
            amount: 20_000_000,
            kind: .income,
            category: .salary,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 250_000,
            kind: .expense,
            category: .food,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 500_000,
            kind: .expense,
            category: .shopping,
            occurredAt: previousMonthDate
        ),
    ]

    let summary = transactions.monthlySummary(
        containing: targetDate,
        calendar: calendar
    )

    #expect(summary.income == 20_000_000)
    #expect(summary.expense == 250_000)
    #expect(summary.balance == 19_750_000)
}

@Test("parses common Vietnamese amount formats")
func parsesCommonVietnameseAmountFormats() {
    #expect(TransactionAmountParser.parse("45000") == 45_000)
    #expect(TransactionAmountParser.parse("45.000") == 45_000)
    #expect(TransactionAmountParser.parse("1.234.000") == 1_234_000)
    #expect(TransactionAmountParser.parse("1234,50") == Decimal(string: "1234.50"))
}

@Test("rejects empty amount input")
func rejectsEmptyAmountInput() {
    #expect(TransactionAmountParser.parse("") == nil)
    #expect(TransactionAmountParser.parse("abc") == nil)
}
