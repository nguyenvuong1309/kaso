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

@Test("calculates current month spending by category")
func calculatesCurrentMonthSpendingByCategory() throws {
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
            amount: 150_000,
            kind: .expense,
            category: .food,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 300_000,
            kind: .expense,
            category: .transport,
            occurredAt: targetDate
        ),
        Transaction(
            amount: 500_000,
            kind: .expense,
            category: .shopping,
            occurredAt: previousMonthDate
        ),
    ]

    let spendings = transactions.monthlyCategorySpendings(
        containing: targetDate,
        calendar: calendar
    )

    #expect(
        spendings == [
            MonthlyCategorySpending(
                category: .food,
                amount: 400_000,
                fraction: 4 / 7
            ),
            MonthlyCategorySpending(
                category: .transport,
                amount: 300_000,
                fraction: 3 / 7
            ),
        ]
    )
}

@Test("parses common Vietnamese amount formats")
func parsesCommonVietnameseAmountFormats() {
    #expect(TransactionAmountParser.parse("45000") == 45_000)
    #expect(TransactionAmountParser.parse("45.000") == 45_000)
    #expect(TransactionAmountParser.parse("1.234.000") == 1_234_000)
    #expect(TransactionAmountParser.parse("1234,50") == Decimal(string: "1234.50"))
}

@Test("formats amount input with Vietnamese grouping separators")
func formatsAmountInputWithVietnameseGroupingSeparators() {
    #expect(TransactionAmountFormatter.formatForEditing("") == "")
    #expect(TransactionAmountFormatter.formatForEditing("0") == "0")
    #expect(TransactionAmountFormatter.formatForEditing("000") == "0")
    #expect(TransactionAmountFormatter.formatForEditing("45000") == "45.000")
    #expect(TransactionAmountFormatter.formatForEditing("1.234.567") == "1.234.567")
    #expect(TransactionAmountFormatter.formatForEditing("1234567890") == "1.234.567.890")
    #expect(TransactionAmountFormatter.formatForEditing("abc12def345") == "12.345")
}

@Test("rejects empty amount input")
func rejectsEmptyAmountInput() {
    #expect(TransactionAmountParser.parse("") == nil)
    #expect(TransactionAmountParser.parse("abc") == nil)
}

@Test("parses receipt OCR lines into draft hints")
func parsesReceiptOCRLinesIntoDraftHints() throws {
    let calendar = Calendar(identifier: .gregorian)
    let expectedDate = try #require(
        DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date
    )
    let result = ReceiptOCRParser.parse(
        lines: [
            "Kaso Coffee",
            "Ngày: 26/04/2026 08:15",
            "Cà phê sữa 45.000đ",
            "Tổng cộng: 120.000 đ",
        ],
        referenceDate: expectedDate,
        calendar: calendar
    )

    #expect(result.merchantName == "Kaso Coffee")
    #expect(result.amount == 120_000)
    #expect(result.occurredAt == expectedDate)
    #expect(result.rawText.contains("Tổng cộng: 120.000 đ"))
}

@Test("receipt OCR parser falls back to reference date")
func receiptOCRParserFallsBackToReferenceDate() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try #require(
        DateComponents(
            calendar: calendar,
            year: 2026,
            month: 4,
            day: 26,
            hour: 13
        ).date
    )
    let result = ReceiptOCRParser.parse(
        lines: [
            "Nhà hàng Kaso",
            "Total VND 230000",
        ],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(result.merchantName == "Nhà hàng Kaso")
    #expect(result.amount == 230_000)
    #expect(result.occurredAt == calendar.startOfDay(for: referenceDate))
}
