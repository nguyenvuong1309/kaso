import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct PersonalityTransactionInputTests {
    @Test("init stores amount, category, and expense flag verbatim")
    func initStoresProperties() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 123_456,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        #expect(input.amount == 123_456)
        #expect(input.categoryID == "food")
        #expect(input.isExpense)
        #expect(input.occurredAt == occurredAt)
    }

    @Test("weekday derives Sunday as 1")
    func weekdaySunday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 14, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 1,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        #expect(input.weekday == 1)
    }

    @Test("weekday derives Monday as 2")
    func weekdayMonday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 1,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        #expect(input.weekday == 2)
    }

    @Test("weekday derives Saturday as 7")
    func weekdaySaturday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
        let input = PersonalityTransactionInput(
            amount: 1,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        #expect(input.weekday == 7)
    }

    @Test("equatable compares amount, category, expense flag, date and weekday")
    func equatable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let occurredAt = try makeDate(year: 2026, month: 6, day: 15, calendar: calendar)
        let other = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let base = PersonalityTransactionInput(
            amount: 50_000,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        let same = PersonalityTransactionInput(
            amount: 50_000,
            categoryID: "food",
            isExpense: true,
            occurredAt: occurredAt,
            calendar: calendar
        )
        let differentDate = PersonalityTransactionInput(
            amount: 50_000,
            categoryID: "food",
            isExpense: true,
            occurredAt: other,
            calendar: calendar
        )
        #expect(base == same)
        #expect(base != differentDate)
    }
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
