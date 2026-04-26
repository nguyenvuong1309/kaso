import Foundation
import Testing
@testable import TransactionDomain

@Test("exports CSV header for empty transactions")
func exportsCSVHeaderForEmptyTransactions() {
    let csv = TransactionCSVExporter.export([])

    #expect(csv == "amount,kind,category_id,category_name,occurred_at,note,receipt_id")
}

@Test("exports transactions as CSV rows")
func exportsTransactionsAsCSVRows() throws {
    let firstDate = try date(
        year: 2026,
        month: 4,
        day: 26,
        hour: 8,
        minute: 15,
        second: 30
    )
    let secondDate = try date(
        year: 2026,
        month: 4,
        day: 27,
        hour: 18,
        minute: 5,
        second: 0
    )
    let transactions = [
        Transaction(
            amount: 125_000,
            kind: .expense,
            category: .food,
            occurredAt: firstDate,
            note: "Breakfast",
            receiptImageIdentifier: "receipt-001"
        ),
        Transaction(
            amount: 20_000_000,
            kind: .income,
            category: .salary,
            occurredAt: secondDate
        ),
    ]

    let csv = TransactionCSVExporter.export(transactions)

    #expect(
        csv == """
        amount,kind,category_id,category_name,occurred_at,note,receipt_id
        125000,expense,food,category.food,2026-04-26T08:15:30Z,Breakfast,receipt-001
        20000000,income,salary,category.salary,2026-04-27T18:05:00Z,,
        """
    )
}

@Test("escapes CSV quotes commas and newlines")
func escapesCSVQuotesCommasAndNewlines() throws {
    let category = TransactionCategory(
        id: "food,home",
        nameKey: "category.\"special\"\nname",
        symbolName: "fork.knife",
        colorName: "mint"
    )
    let transaction = Transaction(
        amount: 45_000,
        kind: .expense,
        category: category,
        occurredAt: try date(
            year: 2026,
            month: 4,
            day: 26,
            hour: 9,
            minute: 0,
            second: 0
        ),
        note: "Cà phê, \"sữa\"\nĐá",
        receiptImageIdentifier: "receipt,001\"x"
    )

    let csv = TransactionCSVExporter.export([transaction])

    #expect(
        csv == """
        amount,kind,category_id,category_name,occurred_at,note,receipt_id
        45000,expense,"food,home","category.""special""
        name",2026-04-26T09:00:00Z,"Cà phê, ""sữa""
        Đá","receipt,001""x"
        """
    )
    #expect(String(decoding: csv.utf8, as: UTF8.self) == csv)
}

private func date(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int
) throws -> Date {
    let timeZone = try #require(TimeZone(secondsFromGMT: 0))
    let calendar = Calendar(identifier: .gregorian)
    return try #require(
        DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        ).date
    )
}
