import Foundation
import Testing
@testable import SpendingMapDomain

struct SpendingMapBuilderTests {
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

    private func entry(
        amount: Decimal,
        latitude: Double,
        longitude: Double,
        occurredAt: Date,
        category: String? = nil
    ) -> SpendingMapEntry {
        SpendingMapEntry(
            label: "Test",
            amount: amount,
            categoryID: category,
            latitude: latitude,
            longitude: longitude,
            occurredAt: occurredAt
        )
    }

    @Test("cluster radius constant matches documented value")
    func clusterRadiusConstant() {
        #expect(SpendingMapBuilder.clusterRadiusDegrees == 0.003)
    }

    @Test("summary propagates the requested period and reference date")
    func summaryPropagatesPeriodAndDate() throws {
        let reference = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let summary = SpendingMapBuilder.build(
            entries: [],
            period: .last90Days,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.period == .last90Days)
        #expect(summary.generatedAt == reference)
    }

    @Test("hotspots are sorted by total amount descending")
    func hotspotsSortedByTotalDescending() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 100_000, latitude: 10.10, longitude: 106.10, occurredAt: occurredAt),
            entry(amount: 900_000, latitude: 10.50, longitude: 106.50, occurredAt: occurredAt),
            entry(amount: 400_000, latitude: 10.90, longitude: 106.90, occurredAt: occurredAt),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 3)
        let totals = summary.hotspots.map(\.totalAmount)
        #expect(totals == [900_000, 400_000, 100_000])
    }

    @Test("centroid is the average of clustered coordinates")
    func centroidAveragesCoordinates() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 100, latitude: 10.0000, longitude: 106.0000, occurredAt: occurredAt),
            entry(amount: 100, latitude: 10.0020, longitude: 106.0020, occurredAt: occurredAt),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        let hotspot = try #require(summary.hotspots.first)
        #expect(hotspot.entryCount == 2)
        #expect(abs(hotspot.latitude - 10.0010) < 1e-9)
        #expect(abs(hotspot.longitude - 106.0010) < 1e-9)
    }

    @Test("hotspot entries are sorted by occurredAt descending")
    func hotspotEntriesSortedByDateDescending() throws {
        let older = try makeDate(year: 2024, month: 6, day: 1, calendar: calendar)
        let newer = try makeDate(year: 2024, month: 6, day: 20, calendar: calendar)
        let oldEntry = entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: older)
        let newEntry = entry(amount: 200, latitude: 10.0010, longitude: 106.0010, occurredAt: newer)
        let summary = SpendingMapBuilder.build(
            entries: [oldEntry, newEntry],
            period: .allTime,
            referenceDate: newer,
            calendar: calendar
        )
        let hotspot = try #require(summary.hotspots.first)
        #expect(hotspot.entries.map(\.occurredAt) == [newer, older])
    }

    @Test("zero amount entries yield zero intensity")
    func zeroAmountYieldsZeroIntensity() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 0, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt),
            entry(amount: 0, latitude: 10.5, longitude: 106.5, occurredAt: occurredAt),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.totalAmount == 0)
        for hotspot in summary.hotspots {
            #expect(hotspot.intensity == 0)
        }
    }

    @Test("hotspot without categorised entries has nil top category")
    func nilTopCategoryWhenNoCategories() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt),
            entry(amount: 200, latitude: 10.0010, longitude: 106.0010, occurredAt: occurredAt),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.hotspots.first?.topCategoryID == nil)
    }

    @Test("entries on the period cutoff boundary are included")
    func boundaryEntryIsIncluded() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        let cutoff = try #require(
            SpendingMapPeriod.last30Days.startDate(referenceDate: reference, calendar: calendar)
        )
        let summary = SpendingMapBuilder.build(
            entries: [entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: cutoff)],
            period: .last30Days,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.entryCount == 1)
    }

    @Test("entry just before the cutoff is excluded")
    func entryBeforeCutoffExcluded() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        let cutoff = try #require(
            SpendingMapPeriod.last30Days.startDate(referenceDate: reference, calendar: calendar)
        )
        let justBefore = cutoff.addingTimeInterval(-1)
        let summary = SpendingMapBuilder.build(
            entries: [entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: justBefore)],
            period: .last30Days,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.isEmpty)
        #expect(summary.entryCount == 0)
    }

    @Test("allTime period keeps even very old entries")
    func allTimeKeepsOldEntries() throws {
        let reference = try makeDate(year: 2024, month: 10, day: 31, calendar: calendar)
        let ancient = try makeDate(year: 2010, month: 1, day: 1, calendar: calendar)
        let summary = SpendingMapBuilder.build(
            entries: [entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: ancient)],
            period: .allTime,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.entryCount == 1)
    }

    @Test("single entry produces full intensity hotspot with matching totals")
    func singleEntryFullIntensity() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let summary = SpendingMapBuilder.build(
            entries: [entry(amount: 250_000, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt, category: "food")],
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        let hotspot = try #require(summary.hotspots.first)
        #expect(summary.totalAmount == 250_000)
        #expect(hotspot.totalAmount == 250_000)
        #expect(hotspot.entryCount == 1)
        #expect(hotspot.intensity == 1.0)
        #expect(hotspot.topCategoryID == "food")
    }

    @Test("entries exactly one cluster-radius apart still merge")
    func exactlyRadiusApartMerges() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let base = entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt)
        let edge = entry(
            amount: 100,
            latitude: 10.0 + SpendingMapBuilder.clusterRadiusDegrees,
            longitude: 106.0 + SpendingMapBuilder.clusterRadiusDegrees,
            occurredAt: occurredAt
        )
        let summary = SpendingMapBuilder.build(
            entries: [base, edge],
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 1)
        #expect(summary.hotspots.first?.entryCount == 2)
    }

    @Test("entries beyond the cluster radius split into separate hotspots")
    func beyondRadiusSplits() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let base = entry(amount: 100, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt)
        let far = entry(
            amount: 100,
            latitude: 10.0 + SpendingMapBuilder.clusterRadiusDegrees + 0.001,
            longitude: 106.0,
            occurredAt: occurredAt
        )
        let summary = SpendingMapBuilder.build(
            entries: [base, far],
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 2)
    }

    @Test("total amount aggregates across all hotspots")
    func totalAmountAggregatesAcrossHotspots() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 100_000, latitude: 10.10, longitude: 106.10, occurredAt: occurredAt),
            entry(amount: 200_000, latitude: 10.50, longitude: 106.50, occurredAt: occurredAt),
            entry(amount: 300_000, latitude: 10.90, longitude: 106.90, occurredAt: occurredAt),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.totalAmount == 600_000)
        #expect(summary.entryCount == 3)
    }

    @Test("category totals tie-break and reflect summed amounts not counts")
    func categoryTotalsBySummedAmount() throws {
        let occurredAt = try makeDate(year: 2024, month: 6, day: 15, calendar: calendar)
        let entries = [
            entry(amount: 50_000, latitude: 10.0, longitude: 106.0, occurredAt: occurredAt, category: "food"),
            entry(amount: 50_000, latitude: 10.0010, longitude: 106.0010, occurredAt: occurredAt, category: "food"),
            entry(amount: 150_000, latitude: 10.0005, longitude: 106.0005, occurredAt: occurredAt, category: "shopping"),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: occurredAt,
            calendar: calendar
        )
        #expect(summary.hotspots.first?.topCategoryID == "shopping")
    }
}
