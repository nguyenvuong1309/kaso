import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("expense stores all provided fields")
func expenseStoresAllFields() throws {
    let calendar = makeExpenseCalendar()
    let avoided = try makeExpenseDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let created = try makeExpenseDate(year: 2026, month: 5, day: 2, calendar: calendar)
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    let expense = PhantomExpense(
        id: try #require(id),
        title: "Bỏ giỏ hàng",
        amount: 250_000,
        category: .shopping,
        avoidedAt: avoided,
        note: "Sale",
        createdAt: created
    )

    #expect(expense.id == id)
    #expect(expense.title == "Bỏ giỏ hàng")
    #expect(expense.amount == 250_000)
    #expect(expense.category == .shopping)
    #expect(expense.avoidedAt == avoided)
    #expect(expense.note == "Sale")
    #expect(expense.createdAt == created)
}

@Test("expense defaults category to other and note to nil")
func expenseDefaults() {
    let expense = PhantomExpense(title: "Không mua", amount: 100_000)

    #expect(expense.category == .other)
    #expect(expense.note == nil)
}

@Test("expense equality distinguishes by id")
func expenseEqualityById() throws {
    let calendar = makeExpenseCalendar()
    let date = try makeExpenseDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let first = PhantomExpense(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")),
        title: "A",
        amount: 1,
        avoidedAt: date,
        createdAt: date
    )
    let same = PhantomExpense(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")),
        title: "A",
        amount: 1,
        avoidedAt: date,
        createdAt: date
    )
    let different = PhantomExpense(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")),
        title: "A",
        amount: 1,
        avoidedAt: date,
        createdAt: date
    )

    #expect(first == same)
    #expect(first != different)
}

@Test("expense survives Codable round-trip")
func expenseCodableRoundTrip() throws {
    let calendar = makeExpenseCalendar()
    let avoided = try makeExpenseDate(year: 2026, month: 6, day: 10, calendar: calendar)
    let created = try makeExpenseDate(year: 2026, month: 6, day: 11, calendar: calendar)
    let expense = PhantomExpense(
        id: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111")),
        title: "Huỷ đăng ký",
        amount: 99_000,
        category: .subscription,
        avoidedAt: avoided,
        note: "Netflix",
        createdAt: created
    )

    let data = try JSONEncoder().encode(expense)
    let decoded = try JSONDecoder().decode(PhantomExpense.self, from: data)

    #expect(decoded == expense)
}

private func makeExpenseCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeExpenseDate(
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
