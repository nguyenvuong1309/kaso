import Foundation
import Testing
@testable import SpendingCalendarDomain

// MARK: - DailySpendingKind

@Test("DailySpendingKind raw values and codable round-trip")
func dailySpendingKindCodableRoundTrip() throws {
    #expect(DailySpendingKind.actual.rawValue == "actual")
    #expect(DailySpendingKind.forecast.rawValue == "forecast")

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for kind in [DailySpendingKind.actual, .forecast] {
        let data = try encoder.encode(kind)
        let decoded = try decoder.decode(DailySpendingKind.self, from: data)
        #expect(decoded == kind)
    }
}

@Test("DailySpendingKind decodes from known raw string")
func dailySpendingKindDecodesFromRaw() throws {
    let data = Data("\"forecast\"".utf8)
    let decoded = try JSONDecoder().decode(DailySpendingKind.self, from: data)
    #expect(decoded == .forecast)
}

// MARK: - DailySpendingItem

@Test("DailySpendingItem stores all provided values")
func dailySpendingItemStoresValues() {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    let item = DailySpendingItem(
        id: id ?? UUID(),
        label: "Cafe",
        amount: 45_000,
        category: "Food"
    )
    #expect(item.id == id)
    #expect(item.label == "Cafe")
    #expect(item.amount == 45_000)
    #expect(item.category == "Food")
}

@Test("DailySpendingItem defaults category to nil")
func dailySpendingItemDefaultsCategoryNil() {
    let item = DailySpendingItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
        label: "Bus",
        amount: 7_000
    )
    #expect(item.category == nil)
}

@Test("DailySpendingItem equality depends on id and fields")
func dailySpendingItemEquality() {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
    let a = DailySpendingItem(id: id, label: "Tea", amount: 20_000, category: nil)
    let b = DailySpendingItem(id: id, label: "Tea", amount: 20_000, category: nil)
    let c = DailySpendingItem(id: id, label: "Tea", amount: 21_000, category: nil)
    #expect(a == b)
    #expect(a != c)
}

// MARK: - DailySpending

@Test("DailySpending id equals its date")
func dailySpendingIdEqualsDate() throws {
    let day = try makeDailyDate(2026, 6, 1)
    let spending = DailySpending(
        date: day,
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0
    )
    #expect(spending.id == day)
}

@Test("DailySpending stores all fields")
func dailySpendingStoresFields() throws {
    let day = try makeDailyDate(2026, 6, 2)
    let item = DailySpendingItem(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID(),
        label: "Lunch",
        amount: 50_000
    )
    let spending = DailySpending(
        date: day,
        total: 50_000,
        kind: .forecast,
        items: [item],
        deltaFromAverage: 0.25
    )
    #expect(spending.date == day)
    #expect(spending.total == 50_000)
    #expect(spending.kind == .forecast)
    #expect(spending.items == [item])
    #expect(spending.deltaFromAverage == 0.25)
}

// MARK: - DailySpendingIntensity

@Test("intensity is empty when total is zero")
func intensityEmptyWhenZero() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 3),
        total: 0,
        kind: .actual,
        items: [],
        deltaFromAverage: 5
    )
    #expect(day.intensity == .empty)
}

@Test("intensity is empty when total is negative")
func intensityEmptyWhenNegative() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 4),
        total: -10,
        kind: .actual,
        items: [],
        deltaFromAverage: 0.9
    )
    #expect(day.intensity == .empty)
}

@Test("intensity is low at the -0.3 boundary")
func intensityLowAtBoundary() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 5),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: -0.3
    )
    #expect(day.intensity == .low)
}

@Test("intensity is medium just above the low boundary")
func intensityMediumJustAboveLow() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 6),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: -0.29
    )
    #expect(day.intensity == .medium)
}

@Test("intensity is medium at zero delta")
func intensityMediumAtZeroDelta() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 7),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0
    )
    #expect(day.intensity == .medium)
}

@Test("intensity is high at the +0.3 boundary")
func intensityHighAtBoundary() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 8),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0.3
    )
    #expect(day.intensity == .high)
}

@Test("intensity is medium just below the high boundary")
func intensityMediumJustBelowHigh() throws {
    let day = DailySpending(
        date: try makeDailyDate(2026, 6, 9),
        total: 100_000,
        kind: .actual,
        items: [],
        deltaFromAverage: 0.29
    )
    #expect(day.intensity == .medium)
}

// MARK: - Helpers

private func makeDailyCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeDailyDate(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: makeDailyCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        ).date
    )
}
