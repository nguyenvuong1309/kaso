import Foundation
import Testing
@testable import TransactionDomain

@Test("validated draft carries injected identifier and all fields")
func validatedDraftCarriesInjectedIdentifier() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000F1"))
    let draft = TransactionDraft(
        amount: 75_000,
        kind: .expense,
        category: .transport,
        occurredAt: occurredAt,
        note: "Grab",
        receiptImageIdentifier: "r-2"
    )

    let transaction = try draft.validated(id: id)

    #expect(transaction.id == id)
    #expect(transaction.amount == 75_000)
    #expect(transaction.kind == .expense)
    #expect(transaction.category == .transport)
    #expect(transaction.occurredAt == occurredAt)
    #expect(transaction.note == "Grab")
    #expect(transaction.receiptImageIdentifier == "r-2")
}

@Test("validated income draft preserves kind and category")
func validatedIncomeDraft() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let draft = TransactionDraft(
        amount: 20_000_000,
        kind: .income,
        category: .salary,
        occurredAt: occurredAt
    )

    let transaction = try draft.validated()

    #expect(transaction.kind == .income)
    #expect(transaction.category == .salary)
    #expect(transaction.note == nil)
    #expect(transaction.receiptImageIdentifier == nil)
}

@Test("validated rejects negative amounts")
func validatedRejectsNegativeAmounts() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let draft = TransactionDraft(
        amount: -1,
        kind: .expense,
        category: .food,
        occurredAt: occurredAt
    )

    #expect(throws: TransactionValidationError.amountMustBePositive) {
        try draft.validated()
    }
}

@Test("smallest positive amount passes validation")
func smallestPositiveAmountPasses() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let draft = TransactionDraft(
        amount: Decimal(string: "0.01") ?? Decimal(1),
        kind: .expense,
        category: .food,
        occurredAt: occurredAt
    )

    let transaction = try draft.validated()

    #expect(transaction.amount == Decimal(string: "0.01"))
}

@Test("validation error is equatable")
func validationErrorEquatable() {
    #expect(TransactionValidationError.amountMustBePositive == TransactionValidationError.amountMustBePositive)
}

@Test("draft value type equality compares all fields")
func draftEquality() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let a = TransactionDraft(amount: 1, kind: .expense, category: .food, occurredAt: occurredAt)
    let b = TransactionDraft(amount: 1, kind: .expense, category: .food, occurredAt: occurredAt)
    let c = TransactionDraft(amount: 2, kind: .expense, category: .food, occurredAt: occurredAt)

    #expect(a == b)
    #expect(a != c)
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
