import Foundation
import Testing
@testable import TransactionDomain

@Test("transaction kind exposes stable identity and localization key")
func transactionKindIdentityAndNameKey() {
    #expect(TransactionKind.income.id == "income")
    #expect(TransactionKind.expense.id == "expense")
    #expect(TransactionKind.income.nameKey == "transaction.kind.income")
    #expect(TransactionKind.expense.nameKey == "transaction.kind.expense")
}

@Test("transaction kind enumerates all known cases")
func transactionKindEnumeratesAllCases() {
    #expect(TransactionKind.allCases == [.income, .expense])
}

@Test("transaction kind round-trips through Codable")
func transactionKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for kind in TransactionKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(TransactionKind.self, from: data)
        #expect(decoded == kind)
    }
}

@Test("transaction stores all provided fields")
func transactionStoresAllFields() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let transaction = Transaction(
        id: id,
        amount: 99_000,
        kind: .expense,
        category: .transport,
        occurredAt: occurredAt,
        note: "Grab",
        receiptImageIdentifier: "receipt-9"
    )

    #expect(transaction.id == id)
    #expect(transaction.amount == 99_000)
    #expect(transaction.kind == .expense)
    #expect(transaction.category == .transport)
    #expect(transaction.occurredAt == occurredAt)
    #expect(transaction.note == "Grab")
    #expect(transaction.receiptImageIdentifier == "receipt-9")
}

@Test("transaction defaults optional fields to nil")
func transactionDefaultsOptionalFieldsToNil() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let transaction = Transaction(
        amount: 1_000,
        kind: .income,
        category: .salary,
        occurredAt: occurredAt
    )

    #expect(transaction.note == nil)
    #expect(transaction.receiptImageIdentifier == nil)
}

@Test("transaction round-trips through Codable")
func transactionCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA"))
    let original = Transaction(
        id: id,
        amount: 250_000,
        kind: .expense,
        category: .food,
        occurredAt: occurredAt,
        note: "Lunch",
        receiptImageIdentifier: "r-1"
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Transaction.self, from: data)

    #expect(decoded == original)
}

@Test("transactions with different identifiers are not equal")
func transactionEqualityDependsOnIdentifier() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let first = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let second = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000011"))
    let a = Transaction(id: first, amount: 1, kind: .expense, category: .food, occurredAt: occurredAt)
    let b = Transaction(id: second, amount: 1, kind: .expense, category: .food, occurredAt: occurredAt)

    #expect(a != b)
}

@Test("sample expense factory applies expected defaults")
func sampleExpenseFactoryDefaults() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000099"))
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let sample = Transaction.sampleExpense(id: id, amount: 12_345, occurredAt: occurredAt)

    #expect(sample.id == id)
    #expect(sample.amount == 12_345)
    #expect(sample.kind == .expense)
    #expect(sample.category == .food)
    #expect(sample.occurredAt == occurredAt)
    #expect(sample.note == "sample.transaction.note")
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
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
