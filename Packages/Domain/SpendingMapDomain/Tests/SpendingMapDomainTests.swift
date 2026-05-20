import Foundation
import Testing
@testable import SpendingMapDomain

struct SpendingMapDomainTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let reference = Date(timeIntervalSince1970: 1_730_000_000) // 2024-10-27 approx

    private func entry(
        label: String = "Test",
        amount: Decimal,
        latitude: Double,
        longitude: Double,
        daysAgo: Int = 0,
        category: String? = nil
    ) -> SpendingMapEntry {
        SpendingMapEntry(
            label: label,
            amount: amount,
            categoryID: category,
            latitude: latitude,
            longitude: longitude,
            occurredAt: calendar.date(byAdding: .day, value: -daysAgo, to: reference) ?? reference
        )
    }

    @Test("empty entries produces empty summary")
    func emptyEntries() {
        let summary = SpendingMapBuilder.build(
            entries: [],
            period: .last30Days,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.isEmpty)
        #expect(summary.totalAmount == 0)
        #expect(summary.entryCount == 0)
    }

    @Test("nearby entries cluster into a single hotspot")
    func clustersNearbyEntries() {
        let entries = [
            entry(amount: 100_000, latitude: 10.7720, longitude: 106.6981),
            entry(amount: 50_000, latitude: 10.7724, longitude: 106.6990),
            entry(amount: 75_000, latitude: 10.7715, longitude: 106.6985),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 1)
        #expect(summary.hotspots.first?.entryCount == 3)
        #expect(summary.hotspots.first?.totalAmount == 225_000)
        #expect(summary.hotspots.first?.intensity == 1.0)
    }

    @Test("far-apart entries do not cluster")
    func farApartDoNotCluster() {
        let entries = [
            entry(amount: 100_000, latitude: 10.7720, longitude: 106.6981),
            entry(amount: 50_000, latitude: 10.8045, longitude: 106.7423),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 2)
    }

    @Test("period filter excludes older entries")
    func periodFilterExcludesOldEntries() {
        let entries = [
            entry(amount: 100_000, latitude: 10.0, longitude: 106.0, daysAgo: 5),
            entry(amount: 100_000, latitude: 11.0, longitude: 107.0, daysAgo: 90),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .last30Days,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.count == 1)
        #expect(summary.entryCount == 1)
    }

    @Test("top category reflects highest spend in cluster")
    func topCategoryReflectsHighestSpend() {
        let entries = [
            entry(amount: 100_000, latitude: 10.77, longitude: 106.69, category: "food"),
            entry(amount: 500_000, latitude: 10.77, longitude: 106.69, category: "shopping"),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: reference,
            calendar: calendar
        )
        #expect(summary.hotspots.first?.topCategoryID == "shopping")
    }

    @Test("intensity scales relative to top hotspot")
    func intensityScaling() {
        let entries = [
            entry(amount: 1_000_000, latitude: 10.77, longitude: 106.69),
            entry(amount: 250_000, latitude: 10.80, longitude: 106.74),
        ]
        let summary = SpendingMapBuilder.build(
            entries: entries,
            period: .allTime,
            referenceDate: reference,
            calendar: calendar
        )
        let topIntensity = summary.hotspots.first?.intensity ?? 0
        let bottomIntensity = summary.hotspots.last?.intensity ?? 0
        #expect(topIntensity == 1.0)
        #expect(bottomIntensity == 0.25)
    }
}
