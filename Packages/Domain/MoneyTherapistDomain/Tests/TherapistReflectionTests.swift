import Foundation
import Testing
@testable import MoneyTherapistDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.calendar = calendar
    components.timeZone = TimeZone(identifier: "UTC")
    return try #require(components.date)
}

private let fixedID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
private let otherID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

@Test("reflection stores all explicitly provided fields verbatim")
func reflectionStoresFields() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 9)
    let reflection = TherapistReflection(
        id: fixedID,
        topic: .stressTrigger,
        note: "Felt anxious buying coffee",
        recordedAt: recordedAt
    )
    #expect(reflection.id == fixedID)
    #expect(reflection.topic == .stressTrigger)
    #expect(reflection.note == "Felt anxious buying coffee")
    #expect(reflection.recordedAt == recordedAt)
}

@Test("reflection note defaults to nil when omitted")
func reflectionNoteDefaultsNil() throws {
    let recordedAt = try makeDate(year: 2026, month: 1, day: 1)
    let reflection = TherapistReflection(
        id: fixedID,
        topic: .generalCheckin,
        recordedAt: recordedAt
    )
    #expect(reflection.note == nil)
}

@Test("reflection allows an empty-string note distinct from nil")
func reflectionEmptyStringNote() throws {
    let recordedAt = try makeDate(year: 2026, month: 3, day: 10)
    let reflection = TherapistReflection(
        id: fixedID,
        topic: .guilt,
        note: "",
        recordedAt: recordedAt
    )
    #expect(reflection.note == "")
    #expect(reflection.note != nil)
}

@Test("reflection id satisfies Identifiable using the supplied id")
func reflectionIdentifiable() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let reflection = TherapistReflection(id: fixedID, topic: .guilt, recordedAt: recordedAt)
    #expect(reflection.id == fixedID)
}

@Test("reflections with identical fields are equal")
func reflectionEquality() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 12)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: recordedAt)
    let rhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: recordedAt)
    #expect(lhs == rhs)
}

@Test("reflections differing only by id are not equal")
func reflectionInequalityById() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: recordedAt)
    let rhs = TherapistReflection(id: otherID, topic: .guilt, note: "n", recordedAt: recordedAt)
    #expect(lhs != rhs)
}

@Test("reflections differing only by topic are not equal")
func reflectionInequalityByTopic() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: recordedAt)
    let rhs = TherapistReflection(
        id: fixedID,
        topic: .comparisonAnxiety,
        note: "n",
        recordedAt: recordedAt
    )
    #expect(lhs != rhs)
}

@Test("reflections differing only by note are not equal")
func reflectionInequalityByNote() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: "a", recordedAt: recordedAt)
    let rhs = TherapistReflection(id: fixedID, topic: .guilt, note: "b", recordedAt: recordedAt)
    #expect(lhs != rhs)
}

@Test("reflections differing only by nil vs empty note are not equal")
func reflectionInequalityByNilNote() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: nil, recordedAt: recordedAt)
    let rhs = TherapistReflection(id: fixedID, topic: .guilt, note: "", recordedAt: recordedAt)
    #expect(lhs != rhs)
}

@Test("reflections differing only by recordedAt are not equal")
func reflectionInequalityByDate() throws {
    let early = try makeDate(year: 2026, month: 6, day: 16, hour: 8)
    let late = try makeDate(year: 2026, month: 6, day: 16, hour: 9)
    let lhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: early)
    let rhs = TherapistReflection(id: fixedID, topic: .guilt, note: "n", recordedAt: late)
    #expect(lhs != rhs)
}

@Test("reflection default initializer generates a unique id per instance")
func reflectionDefaultIdsAreUnique() throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let first = TherapistReflection(topic: .guilt, recordedAt: recordedAt)
    let second = TherapistReflection(topic: .guilt, recordedAt: recordedAt)
    #expect(first.id != second.id)
}
