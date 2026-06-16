import Foundation
import Testing
@testable import GiftTrackerDomain

// MARK: - GiftEventKind

@Test("GiftEventKind exposes all seven cases")
func eventKindAllCases() {
    #expect(GiftEventKind.allCases.count == 7)
    #expect(GiftEventKind.allCases == [
        .tet, .wedding, .newHome, .babyShower, .funeral, .birthday, .other,
    ])
}

@Test("GiftEventKind id equals raw value")
func eventKindIdentifiable() {
    for kind in GiftEventKind.allCases {
        #expect(kind.id == kind.rawValue)
    }
}

@Test("GiftEventKind raw values are stable")
func eventKindRawValues() {
    #expect(GiftEventKind.tet.rawValue == "tet")
    #expect(GiftEventKind.wedding.rawValue == "wedding")
    #expect(GiftEventKind.newHome.rawValue == "newHome")
    #expect(GiftEventKind.babyShower.rawValue == "babyShower")
    #expect(GiftEventKind.funeral.rawValue == "funeral")
    #expect(GiftEventKind.birthday.rawValue == "birthday")
    #expect(GiftEventKind.other.rawValue == "other")
}

@Test("GiftEventKind maps each case to a distinct SF Symbol")
func eventKindSymbolNames() {
    #expect(GiftEventKind.tet.symbolName == "envelope.fill")
    #expect(GiftEventKind.wedding.symbolName == "heart.fill")
    #expect(GiftEventKind.newHome.symbolName == "house.fill")
    #expect(GiftEventKind.babyShower.symbolName == "figure.and.child.holdinghands")
    #expect(GiftEventKind.funeral.symbolName == "leaf.fill")
    #expect(GiftEventKind.birthday.symbolName == "birthday.cake.fill")
    #expect(GiftEventKind.other.symbolName == "gift.fill")

    let symbols = GiftEventKind.allCases.map(\.symbolName)
    #expect(Set(symbols).count == symbols.count)
}

@Test("GiftEventKind nameKey is namespaced by raw value")
func eventKindNameKey() {
    #expect(GiftEventKind.tet.nameKey == "gift.eventKind.tet")
    #expect(GiftEventKind.babyShower.nameKey == "gift.eventKind.babyShower")
    #expect(GiftEventKind.other.nameKey == "gift.eventKind.other")
}

@Test("GiftEventKind decodes from its raw value")
func eventKindCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for kind in GiftEventKind.allCases {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(GiftEventKind.self, from: data)
        #expect(decoded == kind)
    }
}

// MARK: - GiftDirection

@Test("GiftDirection exposes both directions")
func directionAllCases() {
    #expect(GiftDirection.allCases == [.given, .received])
}

@Test("GiftDirection raw values are stable")
func directionRawValues() {
    #expect(GiftDirection.given.rawValue == "given")
    #expect(GiftDirection.received.rawValue == "received")
}

@Test("GiftDirection nameKey is namespaced by raw value")
func directionNameKey() {
    #expect(GiftDirection.given.nameKey == "gift.direction.given")
    #expect(GiftDirection.received.nameKey == "gift.direction.received")
}

@Test("GiftDirection round-trips through Codable")
func directionCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for direction in GiftDirection.allCases {
        let data = try encoder.encode(direction)
        let decoded = try decoder.decode(GiftDirection.self, from: data)
        #expect(decoded == direction)
    }
}

// MARK: - GiftRecord

@Test("GiftRecord stores all initializer values")
func recordInitStoresValues() throws {
    let calendar = Calendar(identifier: .gregorian)
    let eventDate = try makeRecordDate(year: 2026, month: 1, day: 20, calendar: calendar)
    let createdAt = try makeRecordDate(year: 2026, month: 1, day: 21, calendar: calendar)
    let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))

    let record = GiftRecord(
        id: id,
        personName: "Hùng",
        eventKind: .wedding,
        direction: .given,
        amount: 1_000_000,
        eventDate: eventDate,
        note: "Đám cưới",
        createdAt: createdAt
    )

    #expect(record.id == id)
    #expect(record.personName == "Hùng")
    #expect(record.eventKind == .wedding)
    #expect(record.direction == .given)
    #expect(record.amount == 1_000_000)
    #expect(record.eventDate == eventDate)
    #expect(record.note == "Đám cưới")
    #expect(record.createdAt == createdAt)
}

@Test("GiftRecord note defaults to nil")
func recordNoteDefaultsNil() throws {
    let calendar = Calendar(identifier: .gregorian)
    let eventDate = try makeRecordDate(year: 2026, month: 2, day: 1, calendar: calendar)
    let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))

    let record = GiftRecord(
        id: id,
        personName: "Mai",
        eventKind: .tet,
        direction: .received,
        amount: 500_000,
        eventDate: eventDate,
        createdAt: eventDate
    )

    #expect(record.note == nil)
}

@Test("GiftRecord is Equatable across identical values")
func recordEquatable() throws {
    let calendar = Calendar(identifier: .gregorian)
    let eventDate = try makeRecordDate(year: 2026, month: 3, day: 5, calendar: calendar)
    let id = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))

    let lhs = GiftRecord(
        id: id, personName: "A", eventKind: .birthday, direction: .given,
        amount: 200_000, eventDate: eventDate, note: nil, createdAt: eventDate
    )
    let rhs = GiftRecord(
        id: id, personName: "A", eventKind: .birthday, direction: .given,
        amount: 200_000, eventDate: eventDate, note: nil, createdAt: eventDate
    )
    let different = GiftRecord(
        id: id, personName: "A", eventKind: .birthday, direction: .given,
        amount: 300_000, eventDate: eventDate, note: nil, createdAt: eventDate
    )

    #expect(lhs == rhs)
    #expect(lhs != different)
}

@Test("GiftRecord round-trips through Codable including optional note")
func recordCodableRoundTrip() throws {
    let calendar = Calendar(identifier: .gregorian)
    let eventDate = try makeRecordDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let createdAt = try makeRecordDate(year: 2026, month: 4, day: 11, calendar: calendar)
    let id = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444444"))

    let record = GiftRecord(
        id: id, personName: "Lan", eventKind: .funeral, direction: .given,
        amount: 750_000, eventDate: eventDate, note: "Phúng điếu", createdAt: createdAt
    )

    let data = try JSONEncoder().encode(record)
    let decoded = try JSONDecoder().decode(GiftRecord.self, from: data)

    #expect(decoded == record)
    #expect(decoded.note == "Phúng điếu")
}

@Test("GiftRecord round-trips through Codable with nil note")
func recordCodableRoundTripNilNote() throws {
    let calendar = Calendar(identifier: .gregorian)
    let eventDate = try makeRecordDate(year: 2026, month: 5, day: 12, calendar: calendar)
    let id = try #require(UUID(uuidString: "55555555-5555-5555-5555-555555555555"))

    let record = GiftRecord(
        id: id, personName: "Bình", eventKind: .newHome, direction: .received,
        amount: 0, eventDate: eventDate, note: nil, createdAt: eventDate
    )

    let data = try JSONEncoder().encode(record)
    let decoded = try JSONDecoder().decode(GiftRecord.self, from: data)

    #expect(decoded == record)
    #expect(decoded.note == nil)
}

// MARK: - Helpers

private func makeRecordDate(
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
