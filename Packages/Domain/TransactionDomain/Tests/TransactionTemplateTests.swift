import Foundation
import Testing
@testable import TransactionDomain

@Test("template converts to draft for a given date")
func templateConvertsToDraft() throws {
    let calendar = Calendar(identifier: .gregorian)
    let createdAt = try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let template = TransactionTemplate(
        name: "Cà phê sáng",
        kind: .expense,
        amount: 35_000,
        category: .food,
        note: "Highlands",
        createdAt: createdAt
    )

    let draft = template.toDraft(occurredAt: occurredAt)

    #expect(draft.amount == 35_000)
    #expect(draft.kind == .expense)
    #expect(draft.category == .food)
    #expect(draft.note == "Highlands")
    #expect(draft.occurredAt == occurredAt)
    #expect(draft.receiptImageIdentifier == nil)
}

@Test("template without a note produces a draft without a note")
func templateWithoutNote() throws {
    let calendar = Calendar(identifier: .gregorian)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let template = TransactionTemplate(
        name: "Grab đi làm",
        kind: .expense,
        amount: 65_000,
        category: .transport
    )

    let draft = template.toDraft(occurredAt: occurredAt)

    #expect(draft.note == nil)
    #expect(draft.category == .transport)
}

@Test("template round-trips through Codable")
func templateCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let createdAt = try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B2"))
    let original = TransactionTemplate(
        id: id,
        name: "Lương tháng",
        kind: .income,
        amount: 20_000_000,
        category: .salary,
        note: nil,
        createdAt: createdAt
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(TransactionTemplate.self, from: data)

    #expect(decoded == original)
}

@Test("templates with distinct identifiers are not equal")
func templateEqualityUsesIdentifier() throws {
    let calendar = Calendar(identifier: .gregorian)
    let createdAt = try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let first = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
    let second = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C2"))
    let a = TransactionTemplate(id: first, name: "A", kind: .expense, amount: 1, category: .food, createdAt: createdAt)
    let b = TransactionTemplate(id: second, name: "A", kind: .expense, amount: 1, category: .food, createdAt: createdAt)

    #expect(a != b)
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
