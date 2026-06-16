import Foundation
import Testing
@testable import RegretScoreDomain

@Test("reminder builder returns empty for no inputs")
func reminderBuilderEmptyInputs() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let candidates = RegretReminderBuilder.reminders(
        from: [],
        ratings: [],
        referenceDate: now
    )
    #expect(candidates.isEmpty)
}

@Test("reminder builder default thresholds are exposed")
func reminderBuilderDefaults() {
    #expect(RegretReminderBuilder.defaultMinDaysSincePurchase == 7)
    #expect(RegretReminderBuilder.defaultMinAmount == 500_000)
}

@Test("reminder builder sorts candidates by descending amount")
func reminderBuilderSortsByAmount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-10 * 86_400)
    let small = input(title: "Small", amount: 600_000, occurredAt: occurredAt)
    let large = input(title: "Large", amount: 3_000_000, occurredAt: occurredAt)
    let medium = input(title: "Medium", amount: 1_500_000, occurredAt: occurredAt)

    let candidates = RegretReminderBuilder.reminders(
        from: [small, large, medium],
        ratings: [],
        referenceDate: now
    )

    #expect(candidates.map(\.title) == ["Large", "Medium", "Small"])
}

@Test("reminder builder keeps a purchase exactly at the cutoff")
func reminderBuilderCutoffBoundaryInclusive() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let atCutoff = now.addingTimeInterval(-7 * 86_400)
    let candidate = input(title: "Boundary", amount: 600_000, occurredAt: atCutoff)

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [],
        referenceDate: now
    )

    #expect(candidates.count == 1)
    #expect(candidates.first?.title == "Boundary")
}

@Test("reminder builder drops a purchase just newer than the cutoff")
func reminderBuilderRejectsTooRecent() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let justInsideCutoff = now.addingTimeInterval(-7 * 86_400 + 1)
    let candidate = input(title: "TooRecent", amount: 600_000, occurredAt: justInsideCutoff)

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [],
        referenceDate: now
    )

    #expect(candidates.isEmpty)
}

@Test("reminder builder includes a purchase exactly at the minimum amount")
func reminderBuilderAmountBoundaryInclusive() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-10 * 86_400)
    let atMin = input(title: "Exact", amount: 500_000, occurredAt: occurredAt)
    let belowMin = input(title: "Below", amount: 499_999, occurredAt: occurredAt)

    let candidates = RegretReminderBuilder.reminders(
        from: [atMin, belowMin],
        ratings: [],
        referenceDate: now
    )

    #expect(candidates.map(\.title) == ["Exact"])
}

@Test("reminder builder respects custom thresholds")
func reminderBuilderCustomThresholds() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-2 * 86_400)
    let candidate = input(title: "Cheap but old enough", amount: 100_000, occurredAt: occurredAt)

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [],
        referenceDate: now,
        minDaysSincePurchase: 1,
        minAmount: 50_000
    )

    #expect(candidates.count == 1)
    #expect(candidates.first?.title == "Cheap but old enough")
}

@Test("reminder builder dedupes ratings case-insensitively by title day and amount")
func reminderBuilderDedupesCaseInsensitive() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-10 * 86_400)
    let candidate = input(title: "Sneakers", amount: 2_000_000, occurredAt: occurredAt)
    let existing = RegretRating(
        purchaseTitle: "SNEAKERS",
        category: "fashion",
        amount: 2_000_000,
        score: .regret,
        purchasedAt: occurredAt
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [existing],
        referenceDate: now
    )

    #expect(candidates.isEmpty)
}

@Test("reminder builder keeps a purchase when only the amount differs from a rating")
func reminderBuilderKeepsWhenAmountDiffers() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-10 * 86_400)
    let candidate = input(title: "Sneakers", amount: 2_000_000, occurredAt: occurredAt)
    let differentAmount = RegretRating(
        purchaseTitle: "Sneakers",
        category: "fashion",
        amount: 1_999_999,
        score: .regret,
        purchasedAt: occurredAt
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [differentAmount],
        referenceDate: now
    )

    #expect(candidates.count == 1)
}

@Test("reminder builder keeps a purchase rated on a different day")
func reminderBuilderKeepsWhenDayDiffers() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let differentDay = try makeDate(year: 2026, month: 6, day: 2, calendar: calendar)
    let candidate = input(title: "Sneakers", amount: 2_000_000, occurredAt: occurredAt)
    let ratingOnOtherDay = RegretRating(
        purchaseTitle: "Sneakers",
        category: "fashion",
        amount: 2_000_000,
        score: .regret,
        purchasedAt: differentDay
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [candidate],
        ratings: [ratingOnOtherDay],
        referenceDate: now
    )

    #expect(candidates.count == 1)
}

@Test("reminder candidate carries through the input fields")
func reminderCandidateMapsInputFields() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let occurredAt = now.addingTimeInterval(-10 * 86_400)
    let transactionID = try #require(UUID(uuidString: "77777777-7777-7777-7777-777777777777"))
    let candidateInput = RegretReminderInput(
        transactionID: transactionID,
        title: "Drone",
        category: "electronics",
        amount: 5_000_000,
        occurredAt: occurredAt
    )

    let candidates = RegretReminderBuilder.reminders(
        from: [candidateInput],
        ratings: [],
        referenceDate: now
    )

    let candidate = try #require(candidates.first)
    #expect(candidate.transactionID == transactionID)
    #expect(candidate.title == "Drone")
    #expect(candidate.category == "electronics")
    #expect(candidate.amount == 5_000_000)
    #expect(candidate.occurredAt == occurredAt)
}

@Test("reminder candidate stores its own identity and is equatable")
func reminderCandidateValueType() throws {
    let id = try #require(UUID(uuidString: "88888888-8888-8888-8888-888888888888"))
    let txID = try #require(UUID(uuidString: "99999999-9999-9999-9999-999999999999"))
    let occurredAt = Date(timeIntervalSince1970: 1_000)
    let a = RegretReminderCandidate(
        id: id,
        transactionID: txID,
        title: "TV",
        category: "electronics",
        amount: 9_000_000,
        occurredAt: occurredAt
    )
    let b = RegretReminderCandidate(
        id: id,
        transactionID: txID,
        title: "TV",
        category: "electronics",
        amount: 9_000_000,
        occurredAt: occurredAt
    )
    #expect(a == b)
    #expect(a.id == id)
}

@Test("reminder input is equatable")
func reminderInputEquatable() {
    let txID = UUID(uuidString: "10101010-1010-1010-1010-101010101010")
    let occurredAt = Date(timeIntervalSince1970: 2_000)
    let a = RegretReminderInput(
        transactionID: txID ?? UUID(),
        title: "Item",
        category: "food",
        amount: 100,
        occurredAt: occurredAt
    )
    var b = a
    #expect(a == b)
    b.amount = 200
    #expect(a != b)
}

private func input(
    title: String,
    amount: Decimal,
    occurredAt: Date,
    transactionID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
) -> RegretReminderInput {
    RegretReminderInput(
        transactionID: transactionID,
        title: title,
        category: "fashion",
        amount: amount,
        occurredAt: occurredAt
    )
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
