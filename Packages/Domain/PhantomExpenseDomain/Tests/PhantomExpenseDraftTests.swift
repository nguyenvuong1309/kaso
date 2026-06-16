import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("draft default values")
func draftDefaults() {
    let draft = PhantomExpenseDraft()

    #expect(draft.title == "")
    #expect(draft.amount == 0)
    #expect(draft.category == .other)
    #expect(draft.note == nil)
}

@Test("draft initialized from existing expense copies fields")
func draftFromExpense() throws {
    let calendar = makeDraftCalendar()
    let avoided = try makeDraftDate(year: 2026, month: 4, day: 9, calendar: calendar)
    let expense = PhantomExpense(
        id: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222")),
        title: "Bỏ chuyến đi",
        amount: 5_000_000,
        category: .trip,
        avoidedAt: avoided,
        note: "Đợi sale vé",
        createdAt: avoided
    )

    let draft = PhantomExpenseDraft(expense: expense)

    #expect(draft.title == "Bỏ chuyến đi")
    #expect(draft.amount == 5_000_000)
    #expect(draft.category == .trip)
    #expect(draft.avoidedAt == avoided)
    #expect(draft.note == "Đợi sale vé")
}

@Test("validationErrors empty for valid draft")
func validationErrorsEmptyWhenValid() {
    let draft = PhantomExpenseDraft(title: "Hợp lệ", amount: 10_000)
    #expect(draft.validationErrors().isEmpty)
}

@Test("validationErrors reports only title when amount positive")
func validationErrorsTitleOnly() {
    let draft = PhantomExpenseDraft(title: "   ", amount: 10_000)
    #expect(draft.validationErrors() == [.titleRequired])
}

@Test("validationErrors reports only amount when title present")
func validationErrorsAmountOnly() {
    let draft = PhantomExpenseDraft(title: "Có tiêu đề", amount: -5)
    #expect(draft.validationErrors() == [.amountMustBePositive])
}

@Test("validationErrors flags zero amount")
func validationErrorsZeroAmount() {
    let draft = PhantomExpenseDraft(title: "Tiêu đề", amount: 0)
    #expect(draft.validationErrors() == [.amountMustBePositive])
}

@Test("validationErrors preserves order title then amount")
func validationErrorsOrder() {
    let draft = PhantomExpenseDraft(title: "", amount: 0)
    #expect(draft.validationErrors() == [.titleRequired, .amountMustBePositive])
}

@Test("validated produces expense with fixed id and createdAt")
func validatedUsesProvidedValues() throws {
    let calendar = makeDraftCalendar()
    let created = try makeDraftDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let avoided = try makeDraftDate(year: 2026, month: 6, day: 2, calendar: calendar)
    let id = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
    let draft = PhantomExpenseDraft(
        title: "  Không mua điện thoại  ",
        amount: 20_000_000,
        category: .shopping,
        avoidedAt: avoided,
        note: "   "
    )

    let expense = try draft.validated(id: id, createdAt: created)

    #expect(expense.id == id)
    #expect(expense.createdAt == created)
    #expect(expense.avoidedAt == avoided)
    #expect(expense.title == "Không mua điện thoại")
    #expect(expense.amount == 20_000_000)
    #expect(expense.category == .shopping)
    #expect(expense.note == nil)
}

@Test("validated throws first error for invalid draft")
func validatedThrows() {
    let draft = PhantomExpenseDraft(title: "", amount: 0)

    #expect(throws: PhantomExpenseValidationError.titleRequired) {
        _ = try draft.validated()
    }
}

@Test("updating preserves existing id and createdAt")
func updatingPreservesIdentity() throws {
    let calendar = makeDraftCalendar()
    let originalCreated = try makeDraftDate(year: 2025, month: 1, day: 1, calendar: calendar)
    let originalAvoided = try makeDraftDate(year: 2025, month: 1, day: 2, calendar: calendar)
    let newAvoided = try makeDraftDate(year: 2026, month: 2, day: 3, calendar: calendar)
    let id = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
    let existing = PhantomExpense(
        id: id,
        title: "Cũ",
        amount: 1,
        category: .other,
        avoidedAt: originalAvoided,
        note: nil,
        createdAt: originalCreated
    )
    let draft = PhantomExpenseDraft(
        title: " Mới ",
        amount: 500_000,
        category: .entertainment,
        avoidedAt: newAvoided,
        note: " ghi chú "
    )

    let updated = try draft.updating(existing: existing)

    #expect(updated.id == id)
    #expect(updated.createdAt == originalCreated)
    #expect(updated.title == "Mới")
    #expect(updated.amount == 500_000)
    #expect(updated.category == .entertainment)
    #expect(updated.avoidedAt == newAvoided)
    #expect(updated.note == "ghi chú")
}

@Test("updating throws for invalid draft")
func updatingThrows() throws {
    let calendar = makeDraftCalendar()
    let date = try makeDraftDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let existing = PhantomExpense(
        id: try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555")),
        title: "Cũ",
        amount: 1,
        avoidedAt: date,
        createdAt: date
    )
    let draft = PhantomExpenseDraft(title: "Ổn", amount: 0)

    #expect(throws: PhantomExpenseValidationError.amountMustBePositive) {
        _ = try draft.updating(existing: existing)
    }
}

@Test("draft survives Codable round-trip")
func draftCodableRoundTrip() throws {
    let calendar = makeDraftCalendar()
    let avoided = try makeDraftDate(year: 2026, month: 3, day: 15, calendar: calendar)
    let draft = PhantomExpenseDraft(
        title: "Round trip",
        amount: 12_345,
        category: .foodDrink,
        avoidedAt: avoided,
        note: "ghi chú"
    )

    let data = try JSONEncoder().encode(draft)
    let decoded = try JSONDecoder().decode(PhantomExpenseDraft.self, from: data)

    #expect(decoded == draft)
}

@Test("validation error survives Codable round-trip")
func validationErrorCodableRoundTrip() throws {
    for error in [PhantomExpenseValidationError.titleRequired, .amountMustBePositive] {
        let data = try JSONEncoder().encode(error)
        let decoded = try JSONDecoder().decode(PhantomExpenseValidationError.self, from: data)
        #expect(decoded == error)
    }
}

private func makeDraftCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeDraftDate(
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
