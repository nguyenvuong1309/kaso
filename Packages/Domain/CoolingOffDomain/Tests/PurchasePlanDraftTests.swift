import Foundation
import Testing
@testable import CoolingOffDomain

@Test("draft init from plan copies editable fields")
func draftFromPlan() throws {
    let now = try makeDate(year: 2026, month: 3, day: 10, hour: 9)
    let plan = PurchasePlan(
        title: "Watch",
        amount: 9_000_000,
        category: .fashion,
        note: "Gift",
        coolingPeriod: .oneWeek,
        availableAt: now
    )
    let draft = PurchasePlanDraft(plan: plan)
    #expect(draft.title == "Watch")
    #expect(draft.amount == 9_000_000)
    #expect(draft.category == .fashion)
    #expect(draft.coolingPeriod == .oneWeek)
    #expect(draft.note == "Gift")
}

@Test("draft has no validation errors when valid")
func draftValidNoErrors() {
    let draft = PurchasePlanDraft(title: "Bag", amount: 1)
    #expect(draft.validationErrors().isEmpty)
}

@Test("draft reports only title error when amount is valid")
func draftTitleErrorOnly() {
    let draft = PurchasePlanDraft(title: "   ", amount: 100)
    #expect(draft.validationErrors() == [.titleRequired])
}

@Test("draft reports only amount error when title is valid")
func draftAmountErrorOnly() {
    let draft = PurchasePlanDraft(title: "Bag", amount: -5)
    #expect(draft.validationErrors() == [.amountMustBePositive])
}

@Test("draft amount error order follows title then amount")
func draftErrorOrder() {
    let draft = PurchasePlanDraft(title: "", amount: 0)
    #expect(draft.validationErrors() == [.titleRequired, .amountMustBePositive])
}

@Test("draft validated throws titleRequired first")
func draftValidatedThrowsTitle() throws {
    let draft = PurchasePlanDraft(title: " ", amount: 0)
    #expect(throws: PurchasePlanValidationError.titleRequired) {
        _ = try draft.validated()
    }
}

@Test("draft validated throws amountMustBePositive when title valid")
func draftValidatedThrowsAmount() {
    let draft = PurchasePlanDraft(title: "Bag", amount: 0)
    #expect(throws: PurchasePlanValidationError.amountMustBePositive) {
        _ = try draft.validated()
    }
}

@Test("draft validated trims title and note")
func draftValidatedTrims() throws {
    let now = try makeDate(year: 2026, month: 3, day: 10, hour: 9)
    let draft = PurchasePlanDraft(
        title: "  Sofa  ",
        amount: 5_000_000,
        note: "  comfy  "
    )
    let plan = try draft.validated(now: now)
    #expect(plan.title == "Sofa")
    #expect(plan.note == "comfy")
}

@Test("draft validated turns blank note into nil")
func draftValidatedBlankNote() throws {
    let now = try makeDate(year: 2026, month: 3, day: 10, hour: 9)
    let draft = PurchasePlanDraft(title: "Sofa", amount: 5_000_000, note: "   ")
    let plan = try draft.validated(now: now)
    #expect(plan.note == nil)
}

@Test("draft validated keeps nil note as nil")
func draftValidatedNilNote() throws {
    let now = try makeDate(year: 2026, month: 3, day: 10, hour: 9)
    let draft = PurchasePlanDraft(title: "Sofa", amount: 5_000_000, note: nil)
    let plan = try draft.validated(now: now)
    #expect(plan.note == nil)
}

@Test("draft validated uses provided id and waiting status")
func draftValidatedUsesId() throws {
    let now = try makeDate(year: 2026, month: 3, day: 10, hour: 9)
    let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    let draft = PurchasePlanDraft(title: "Sofa", amount: 5_000_000, coolingPeriod: .oneWeek)
    let plan = try draft.validated(id: id, now: now)
    #expect(plan.id == id)
    #expect(plan.status == .waiting)
    #expect(plan.createdAt == now)
    #expect(plan.availableAt == now.addingTimeInterval(7 * 86_400))
}

@Test("draft updating keeps availableAt when cooling period unchanged")
func draftUpdatingKeepsAvailableAt() throws {
    let created = try makeDate(year: 2026, month: 3, day: 1, hour: 9)
    let now = try makeDate(year: 2026, month: 3, day: 5, hour: 9)
    let id = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
    let existing = PurchasePlan(
        id: id,
        title: "Old",
        amount: 1_000_000,
        category: .home,
        coolingPeriod: .threeDays,
        status: .waiting,
        createdAt: created,
        availableAt: created.addingTimeInterval(3 * 86_400),
        decisionAt: nil
    )
    let draft = PurchasePlanDraft(
        title: "New",
        amount: 2_000_000,
        category: .electronics,
        coolingPeriod: .threeDays
    )
    let updated = try draft.updating(existing: existing, now: now)
    #expect(updated.id == id)
    #expect(updated.title == "New")
    #expect(updated.amount == 2_000_000)
    #expect(updated.category == .electronics)
    #expect(updated.createdAt == created)
    #expect(updated.availableAt == existing.availableAt)
    #expect(updated.status == .waiting)
}

@Test("draft updating recomputes availableAt when cooling period changes")
func draftUpdatingRecomputesAvailableAt() throws {
    let created = try makeDate(year: 2026, month: 3, day: 1, hour: 9)
    let now = try makeDate(year: 2026, month: 3, day: 5, hour: 9)
    let id = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
    let existing = PurchasePlan(
        id: id,
        title: "Old",
        amount: 1_000_000,
        coolingPeriod: .threeDays,
        status: .waiting,
        createdAt: created,
        availableAt: created.addingTimeInterval(3 * 86_400)
    )
    let draft = PurchasePlanDraft(title: "New", amount: 2_000_000, coolingPeriod: .twoWeeks)
    let updated = try draft.updating(existing: existing, now: now)
    #expect(updated.coolingPeriod == .twoWeeks)
    #expect(updated.availableAt == created.addingTimeInterval(14 * 86_400))
}

@Test("draft updating preserves existing status and decisionAt")
func draftUpdatingPreservesStatus() throws {
    let created = try makeDate(year: 2026, month: 3, day: 1, hour: 9)
    let decision = try makeDate(year: 2026, month: 3, day: 4, hour: 9)
    let now = try makeDate(year: 2026, month: 3, day: 5, hour: 9)
    let id = try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555"))
    let existing = PurchasePlan(
        id: id,
        title: "Old",
        amount: 1_000_000,
        coolingPeriod: .threeDays,
        status: .approved,
        createdAt: created,
        availableAt: created.addingTimeInterval(3 * 86_400),
        decisionAt: decision
    )
    let draft = PurchasePlanDraft(title: "New", amount: 2_000_000, coolingPeriod: .threeDays)
    let updated = try draft.updating(existing: existing, now: now)
    #expect(updated.status == .approved)
    #expect(updated.decisionAt == decision)
}

@Test("draft updating throws when invalid")
func draftUpdatingThrows() throws {
    let created = try makeDate(year: 2026, month: 3, day: 1, hour: 9)
    let now = try makeDate(year: 2026, month: 3, day: 5, hour: 9)
    let existing = PurchasePlan(
        title: "Old",
        amount: 1_000_000,
        coolingPeriod: .threeDays,
        createdAt: created,
        availableAt: created.addingTimeInterval(3 * 86_400)
    )
    let draft = PurchasePlanDraft(title: "", amount: 0)
    #expect(throws: PurchasePlanValidationError.titleRequired) {
        _ = try draft.updating(existing: existing, now: now)
    }
}

@Test("validation error message keys follow localization convention")
func validationErrorMessageKeys() {
    #expect(PurchasePlanValidationError.titleRequired.messageKey == "coolingOff.error.titleRequired")
    #expect(PurchasePlanValidationError.amountMustBePositive.messageKey == "coolingOff.error.amountMustBePositive")
}

@Test("draft round-trips through Codable")
func draftCodableRoundTrip() throws {
    let draft = PurchasePlanDraft(
        title: "Lamp",
        amount: 750_000,
        category: .home,
        coolingPeriod: .oneDay,
        note: "warm light"
    )
    let data = try JSONEncoder().encode(draft)
    let decoded = try JSONDecoder().decode(PurchasePlanDraft.self, from: data)
    #expect(decoded == draft)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = fixedCalendar()
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
