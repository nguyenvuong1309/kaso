import Foundation
import Testing
@testable import RoundUpDomain

@Test("entry init stores all provided fields")
func entryInitStoresFields() throws {
    let id = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
    let txnID = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
    let goalID = try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555"))
    let created = try makeDate(year: 2026, month: 6, day: 1)

    let entry = RoundUpEntry(
        id: id,
        sourceTransactionID: txnID,
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        savingGoalID: goalID,
        note: "coffee",
        createdAt: created
    )

    #expect(entry.id == id)
    #expect(entry.sourceTransactionID == txnID)
    #expect(entry.originalAmount == 85_000)
    #expect(entry.roundedAmount == 90_000)
    #expect(entry.contribution == 5_000)
    #expect(entry.step == .tenThousand)
    #expect(entry.savingGoalID == goalID)
    #expect(entry.note == "coffee")
    #expect(entry.createdAt == created)
}

@Test("entry init applies optional defaults")
func entryInitDefaults() {
    let entry = RoundUpEntry(
        originalAmount: 1,
        roundedAmount: 1_000,
        contribution: 999,
        step: .oneThousand
    )

    #expect(entry.sourceTransactionID == nil)
    #expect(entry.savingGoalID == nil)
    #expect(entry.note == nil)
}

@Test("entry equatable compares all stored values")
func entryEquatable() throws {
    let id = try #require(UUID(uuidString: "66666666-6666-6666-6666-666666666666"))
    let created = try makeDate(year: 2026, month: 6, day: 1)

    let a = RoundUpEntry(
        id: id,
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        createdAt: created
    )
    let b = RoundUpEntry(
        id: id,
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        createdAt: created
    )
    let differentContribution = RoundUpEntry(
        id: id,
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 4_000,
        step: .tenThousand,
        createdAt: created
    )

    #expect(a == b)
    #expect(a != differentContribution)
}

@Test("entry Codable round-trips preserving all fields")
func entryCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "77777777-7777-7777-7777-777777777777"))
    let txnID = try #require(UUID(uuidString: "88888888-8888-8888-8888-888888888888"))
    let created = try makeDate(year: 2026, month: 6, day: 16, hour: 9)

    let entry = RoundUpEntry(
        id: id,
        sourceTransactionID: txnID,
        originalAmount: 32_500,
        roundedAmount: 35_000,
        contribution: 2_500,
        step: .fiveThousand,
        savingGoalID: nil,
        note: "groceries",
        createdAt: created
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let data = try encoder.encode(entry)
    let decoded = try decoder.decode(RoundUpEntry.self, from: data)
    #expect(decoded == entry)
    #expect(decoded.note == "groceries")
    #expect(decoded.savingGoalID == nil)
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var calendar = calendar
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return try #require(
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
