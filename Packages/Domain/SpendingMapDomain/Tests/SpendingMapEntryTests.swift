import Foundation
import Testing
@testable import SpendingMapDomain

struct SpendingMapEntryTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = TimeZone(identifier: "UTC")
        return try #require(calendar.date(from: components))
    }

    private let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")

    @Test("initializer stores all provided properties")
    func initializerStoresProperties() throws {
        let id = try #require(fixedID)
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entry = SpendingMapEntry(
            id: id,
            label: "Cà phê",
            amount: 65_000,
            categoryID: "food",
            latitude: 10.7720,
            longitude: 106.6981,
            occurredAt: occurredAt,
            note: "morning"
        )
        #expect(entry.id == id)
        #expect(entry.label == "Cà phê")
        #expect(entry.amount == Decimal(65_000))
        #expect(entry.categoryID == "food")
        #expect(entry.latitude == 10.7720)
        #expect(entry.longitude == 106.6981)
        #expect(entry.occurredAt == occurredAt)
        #expect(entry.note == "morning")
    }

    @Test("default initializer leaves optional fields nil")
    func defaultOptionalsAreNil() throws {
        let occurredAt = try makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        let entry = SpendingMapEntry(
            label: "Test",
            amount: 100,
            latitude: 0,
            longitude: 0,
            occurredAt: occurredAt
        )
        #expect(entry.categoryID == nil)
        #expect(entry.note == nil)
    }

    @Test("entries with same fields and id are equal")
    func equalityHonoursAllFields() throws {
        let id = try #require(fixedID)
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let lhs = SpendingMapEntry(
            id: id,
            label: "A",
            amount: 100,
            categoryID: "food",
            latitude: 1,
            longitude: 2,
            occurredAt: occurredAt
        )
        let rhs = SpendingMapEntry(
            id: id,
            label: "A",
            amount: 100,
            categoryID: "food",
            latitude: 1,
            longitude: 2,
            occurredAt: occurredAt
        )
        #expect(lhs == rhs)
    }

    @Test("entries differing only by id are not equal")
    func equalityDistinguishesID() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let lhs = SpendingMapEntry(
            id: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111")),
            label: "A",
            amount: 100,
            latitude: 1,
            longitude: 2,
            occurredAt: occurredAt
        )
        let rhs = SpendingMapEntry(
            id: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222")),
            label: "A",
            amount: 100,
            latitude: 1,
            longitude: 2,
            occurredAt: occurredAt
        )
        #expect(lhs != rhs)
    }

    @Test("entry round-trips through Codable preserving all fields")
    func codableRoundTrip() throws {
        let id = try #require(fixedID)
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entry = SpendingMapEntry(
            id: id,
            label: "Mua áo",
            amount: 850_000,
            categoryID: "shopping",
            latitude: 10.7800,
            longitude: 106.7012,
            occurredAt: occurredAt,
            note: "sale"
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SpendingMapEntry.self, from: data)
        #expect(decoded == entry)
    }

    @Test("entry with nil optionals round-trips through Codable")
    func codableRoundTripWithNilOptionals() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entry = SpendingMapEntry(
            id: try #require(fixedID),
            label: "Test",
            amount: 100,
            latitude: 0,
            longitude: 0,
            occurredAt: occurredAt
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SpendingMapEntry.self, from: data)
        #expect(decoded == entry)
        #expect(decoded.categoryID == nil)
        #expect(decoded.note == nil)
    }
}
