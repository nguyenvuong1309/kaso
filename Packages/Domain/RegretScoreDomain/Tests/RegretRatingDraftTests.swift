import Foundation
import Testing
@testable import RegretScoreDomain

@Test("draft default initializer uses neutral defaults")
func draftDefaultInitializer() {
    let draft = RegretRatingDraft()
    #expect(draft.purchaseTitle == "")
    #expect(draft.category == "other")
    #expect(draft.amount == 0)
    #expect(draft.score == .neutral)
    #expect(draft.note == nil)
}

@Test("draft copies fields from an existing rating")
func draftFromExistingRating() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 4, day: 6, calendar: calendar)
    let rating = RegretRating(
        purchaseTitle: "Watch",
        category: "fashion",
        amount: 3_000_000,
        score: .strongRegret,
        note: "Too expensive",
        purchasedAt: purchasedAt
    )

    let draft = RegretRatingDraft(rating: rating)

    #expect(draft.purchaseTitle == "Watch")
    #expect(draft.category == "fashion")
    #expect(draft.amount == 3_000_000)
    #expect(draft.score == .strongRegret)
    #expect(draft.note == "Too expensive")
    #expect(draft.purchasedAt == purchasedAt)
}

@Test("validationErrors empty for a valid draft")
func validationErrorsEmptyWhenValid() {
    let draft = RegretRatingDraft(purchaseTitle: "Lamp", amount: 250_000)
    #expect(draft.validationErrors().isEmpty)
}

@Test("validationErrors flags a blank or whitespace-only title")
func validationErrorsBlankTitle() {
    let blank = RegretRatingDraft(purchaseTitle: "", amount: 100)
    #expect(blank.validationErrors() == [.titleRequired])

    let whitespace = RegretRatingDraft(purchaseTitle: "   \n\t", amount: 100)
    #expect(whitespace.validationErrors() == [.titleRequired])
}

@Test("validationErrors flags non-positive amounts")
func validationErrorsNonPositiveAmount() {
    let zero = RegretRatingDraft(purchaseTitle: "Item", amount: 0)
    #expect(zero.validationErrors() == [.amountMustBePositive])

    let negative = RegretRatingDraft(purchaseTitle: "Item", amount: -50)
    #expect(negative.validationErrors() == [.amountMustBePositive])
}

@Test("validationErrors reports both errors and keeps title first")
func validationErrorsBothInOrder() {
    let draft = RegretRatingDraft(purchaseTitle: "  ", amount: 0)
    #expect(draft.validationErrors() == [.titleRequired, .amountMustBePositive])
}

@Test("validated trims the title and applies the provided id and now")
func validatedTrimsAndAppliesIdentity() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let now = try makeDate(year: 2026, month: 1, day: 15, calendar: calendar)
    let id = try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555"))
    let draft = RegretRatingDraft(
        purchaseTitle: "  Jacket  ",
        category: "fashion",
        amount: 1_200_000,
        score: .regret,
        note: "  hmm  ",
        purchasedAt: purchasedAt
    )

    let rating = try draft.validated(id: id, now: now)

    #expect(rating.id == id)
    #expect(rating.purchaseTitle == "Jacket")
    #expect(rating.category == "fashion")
    #expect(rating.amount == 1_200_000)
    #expect(rating.score == .regret)
    #expect(rating.note == "hmm")
    #expect(rating.purchasedAt == purchasedAt)
    #expect(rating.ratedAt == now)
}

@Test("validated falls back to other when category is empty")
func validatedEmptyCategoryFallback() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 2, day: 1, calendar: calendar)
    let draft = RegretRatingDraft(purchaseTitle: "Snack", category: "", amount: 30_000)

    let rating = try draft.validated(now: now)

    #expect(rating.category == "other")
}

@Test("validated reduces a whitespace-only note to nil")
func validatedWhitespaceNoteBecomesNil() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 2, day: 2, calendar: calendar)
    let draft = RegretRatingDraft(
        purchaseTitle: "Pen",
        amount: 20_000,
        note: "   "
    )

    let rating = try draft.validated(now: now)

    #expect(rating.note == nil)
}

@Test("validated throws the first validation error")
func validatedThrowsFirstError() {
    let draft = RegretRatingDraft(purchaseTitle: "", amount: 0)
    #expect(throws: RegretRatingValidationError.titleRequired) {
        _ = try draft.validated(now: Date(timeIntervalSince1970: 0))
    }
}

@Test("updating preserves the existing identity and applies now")
func updatingPreservesIdentity() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 3, day: 3, calendar: calendar)
    let originalRatedAt = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
    let updatedNow = try makeDate(year: 2026, month: 3, day: 20, calendar: calendar)
    let existing = RegretRating(
        id: try #require(UUID(uuidString: "66666666-6666-6666-6666-666666666666")),
        purchaseTitle: "Old",
        category: "food",
        amount: 100_000,
        score: .neutral,
        purchasedAt: purchasedAt,
        ratedAt: originalRatedAt
    )
    let draft = RegretRatingDraft(
        purchaseTitle: "  New Title  ",
        category: "fashion",
        amount: 999_000,
        score: .strongRegret,
        purchasedAt: purchasedAt
    )

    let updated = try draft.updating(existing: existing, now: updatedNow)

    #expect(updated.id == existing.id)
    #expect(updated.purchaseTitle == "New Title")
    #expect(updated.category == "fashion")
    #expect(updated.amount == 999_000)
    #expect(updated.score == .strongRegret)
    #expect(updated.ratedAt == updatedNow)
}

@Test("updating uses other when category is empty")
func updatingEmptyCategoryFallback() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 4, day: 4, calendar: calendar)
    let now = try makeDate(year: 2026, month: 4, day: 12, calendar: calendar)
    let existing = RegretRating(
        purchaseTitle: "Item",
        category: "food",
        amount: 100_000,
        score: .neutral,
        purchasedAt: purchasedAt
    )
    let draft = RegretRatingDraft(purchaseTitle: "Item", category: "", amount: 200_000)

    let updated = try draft.updating(existing: existing, now: now)

    #expect(updated.category == "other")
}

@Test("updating throws when the draft is invalid")
func updatingThrowsOnInvalidDraft() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 5, day: 5, calendar: calendar)
    let existing = RegretRating(
        purchaseTitle: "Item",
        category: "food",
        amount: 100_000,
        score: .neutral,
        purchasedAt: purchasedAt
    )
    let draft = RegretRatingDraft(purchaseTitle: "Valid", amount: -1)

    #expect(throws: RegretRatingValidationError.amountMustBePositive) {
        _ = try draft.updating(existing: existing, now: Date(timeIntervalSince1970: 0))
    }
}

@Test("validation error message keys map per case")
func validationErrorMessageKeys() {
    #expect(RegretRatingValidationError.titleRequired.messageKey == "regret.error.titleRequired")
    #expect(RegretRatingValidationError.amountMustBePositive.messageKey == "regret.error.amountMustBePositive")
}

@Test("validation error codable round-trips")
func validationErrorCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for error in [RegretRatingValidationError.titleRequired, .amountMustBePositive] {
        let data = try encoder.encode(error)
        let decoded = try decoder.decode(RegretRatingValidationError.self, from: data)
        #expect(decoded == error)
    }
}

@Test("draft codable round-trips")
func draftCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let purchasedAt = try makeDate(year: 2026, month: 6, day: 6, calendar: calendar)
    let draft = RegretRatingDraft(
        purchaseTitle: "Gadget",
        category: "electronics",
        amount: 1_750_000,
        score: .regret,
        note: "regretful",
        purchasedAt: purchasedAt
    )

    let data = try JSONEncoder().encode(draft)
    let decoded = try JSONDecoder().decode(RegretRatingDraft.self, from: data)

    #expect(decoded == draft)
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
