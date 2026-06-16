import Foundation
import Testing
@testable import MoodJournalDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    let components = DateComponents(
        calendar: calendar,
        year: year,
        month: month,
        day: day,
        hour: hour
    )
    return try #require(components.date)
}

@Test("explicit initializer stores all provided values")
func moodEntryExplicitInit() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let txnA = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1"))
    let txnB = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A2"))
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 9)

    let entry = MoodEntry(
        id: id,
        mood: .stressed,
        spendingTotalSnapshot: 1_250_000,
        transactionIDs: [txnA, txnB],
        note: "Impulse coffee run",
        recordedAt: recordedAt
    )

    #expect(entry.id == id)
    #expect(entry.mood == .stressed)
    #expect(entry.spendingTotalSnapshot == Decimal(1_250_000))
    #expect(entry.transactionIDs == [txnA, txnB])
    #expect(entry.note == "Impulse coffee run")
    #expect(entry.recordedAt == recordedAt)
}

@Test("default initializer values are applied")
func moodEntryDefaults() throws {
    let entry = MoodEntry(mood: .good)
    #expect(entry.spendingTotalSnapshot == Decimal(0))
    #expect(entry.transactionIDs.isEmpty)
    #expect(entry.note == nil)
}

@Test("properties are mutable after construction")
func moodEntryMutation() throws {
    let recordedAt = try makeDate(year: 2026, month: 1, day: 1)
    var entry = MoodEntry(mood: .neutral, recordedAt: recordedAt)
    entry.mood = .sad
    entry.spendingTotalSnapshot = 99_000
    entry.note = "updated"
    #expect(entry.mood == .sad)
    #expect(entry.spendingTotalSnapshot == Decimal(99_000))
    #expect(entry.note == "updated")
}

@Test("equatable distinguishes entries that differ in any field")
func moodEntryEquatable() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let recordedAt = try makeDate(year: 2026, month: 3, day: 10)
    let base = MoodEntry(
        id: id,
        mood: .good,
        spendingTotalSnapshot: 100_000,
        transactionIDs: [],
        note: nil,
        recordedAt: recordedAt
    )
    let same = MoodEntry(
        id: id,
        mood: .good,
        spendingTotalSnapshot: 100_000,
        transactionIDs: [],
        note: nil,
        recordedAt: recordedAt
    )
    let differentMood = MoodEntry(
        id: id,
        mood: .anxious,
        spendingTotalSnapshot: 100_000,
        transactionIDs: [],
        note: nil,
        recordedAt: recordedAt
    )

    #expect(base == same)
    #expect(base != differentMood)
}

@Test("codable round-trip preserves all fields including nil note")
func moodEntryCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000020"))
    let txn = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 12)
    let entry = MoodEntry(
        id: id,
        mood: .great,
        spendingTotalSnapshot: 2_000_000,
        transactionIDs: [txn],
        note: nil,
        recordedAt: recordedAt
    )

    let data = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(MoodEntry.self, from: data)
    #expect(decoded == entry)
    #expect(decoded.note == nil)
}

@Test("codable round-trip preserves a present note and decimal precision")
func moodEntryCodablePreservesNoteAndDecimal() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let entry = MoodEntry(
        mood: .sad,
        spendingTotalSnapshot: Decimal(string: "123456.78") ?? 0,
        note: "Bữa tối đắt đỏ",
        recordedAt: recordedAt
    )
    let data = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(MoodEntry.self, from: data)
    #expect(decoded.note == "Bữa tối đắt đỏ")
    #expect(decoded.spendingTotalSnapshot == entry.spendingTotalSnapshot)
}
