import Foundation
import Testing
@testable import SpendingMapDomain

struct SpendingMapHotspotTests {
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

    private func makeEntry(
        id: String,
        amount: Decimal,
        occurredAt: Date
    ) throws -> SpendingMapEntry {
        SpendingMapEntry(
            id: try #require(UUID(uuidString: id)),
            label: "Entry",
            amount: amount,
            latitude: 10,
            longitude: 106,
            occurredAt: occurredAt
        )
    }

    @Test("hotspot initializer stores all provided properties")
    func hotspotStoresProperties() throws {
        let hotspotID = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
        let occurredAt = try makeDate(year: 2024, month: 5, day: 1, calendar: calendar)
        let entry = try makeEntry(id: "44444444-4444-4444-4444-444444444444", amount: 100, occurredAt: occurredAt)
        let hotspot = SpendingMapHotspot(
            id: hotspotID,
            latitude: 10.5,
            longitude: 106.5,
            totalAmount: 100,
            entryCount: 1,
            topCategoryID: "food",
            entries: [entry],
            intensity: 0.5
        )
        #expect(hotspot.id == hotspotID)
        #expect(hotspot.latitude == 10.5)
        #expect(hotspot.longitude == 106.5)
        #expect(hotspot.totalAmount == Decimal(100))
        #expect(hotspot.entryCount == 1)
        #expect(hotspot.topCategoryID == "food")
        #expect(hotspot.entries == [entry])
        #expect(hotspot.intensity == 0.5)
    }

    @Test("hotspots with identical fields and id are equal")
    func hotspotEquality() throws {
        let hotspotID = try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
        let occurredAt = try makeDate(year: 2024, month: 5, day: 1, calendar: calendar)
        let entry = try makeEntry(id: "44444444-4444-4444-4444-444444444444", amount: 100, occurredAt: occurredAt)
        let lhs = SpendingMapHotspot(
            id: hotspotID,
            latitude: 10,
            longitude: 106,
            totalAmount: 100,
            entryCount: 1,
            topCategoryID: nil,
            entries: [entry],
            intensity: 1
        )
        let rhs = SpendingMapHotspot(
            id: hotspotID,
            latitude: 10,
            longitude: 106,
            totalAmount: 100,
            entryCount: 1,
            topCategoryID: nil,
            entries: [entry],
            intensity: 1
        )
        #expect(lhs == rhs)
    }

    @Test("summary initializer stores all provided properties")
    func summaryStoresProperties() throws {
        let generatedAt = try makeDate(year: 2024, month: 5, day: 1, calendar: calendar)
        let summary = SpendingMapSummary(
            hotspots: [],
            totalAmount: 500,
            entryCount: 3,
            period: .last90Days,
            generatedAt: generatedAt
        )
        #expect(summary.hotspots.isEmpty)
        #expect(summary.totalAmount == Decimal(500))
        #expect(summary.entryCount == 3)
        #expect(summary.period == .last90Days)
        #expect(summary.generatedAt == generatedAt)
    }

    @Test("empty summary exposes neutral defaults")
    func emptySummaryDefaults() {
        let summary = SpendingMapSummary.empty
        #expect(summary.hotspots.isEmpty)
        #expect(summary.totalAmount == 0)
        #expect(summary.entryCount == 0)
        #expect(summary.period == .last30Days)
        #expect(summary.generatedAt == Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test("summaries with identical fields are equal")
    func summaryEquality() throws {
        let generatedAt = try makeDate(year: 2024, month: 5, day: 1, calendar: calendar)
        let lhs = SpendingMapSummary(
            hotspots: [],
            totalAmount: 100,
            entryCount: 1,
            period: .allTime,
            generatedAt: generatedAt
        )
        let rhs = SpendingMapSummary(
            hotspots: [],
            totalAmount: 100,
            entryCount: 1,
            period: .allTime,
            generatedAt: generatedAt
        )
        #expect(lhs == rhs)
    }
}
