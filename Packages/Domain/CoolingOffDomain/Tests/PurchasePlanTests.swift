import Foundation
import Testing
@testable import CoolingOffDomain

@Test("plan remainingSeconds is positive before availableAt")
func planRemainingSecondsBefore() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(
        title: "Camera",
        amount: 8_000_000,
        availableAt: now.addingTimeInterval(3_600)
    )
    #expect(plan.remainingSeconds(asOf: now) == 3_600)
}

@Test("plan remainingSeconds clamps to zero after availableAt")
func planRemainingSecondsAfter() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(
        title: "Camera",
        amount: 8_000_000,
        availableAt: now.addingTimeInterval(-3_600)
    )
    #expect(plan.remainingSeconds(asOf: now) == 0)
}

@Test("plan remainingSeconds is zero exactly at availableAt")
func planRemainingSecondsAtBoundary() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(title: "Camera", amount: 8_000_000, availableAt: now)
    #expect(plan.remainingSeconds(asOf: now) == 0)
}

@Test("plan isReady is false before availableAt")
func planIsReadyBefore() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(
        title: "Camera",
        amount: 8_000_000,
        availableAt: now.addingTimeInterval(1)
    )
    #expect(plan.isReady(asOf: now) == false)
}

@Test("plan isReady is true exactly at availableAt")
func planIsReadyAtBoundary() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(title: "Camera", amount: 8_000_000, availableAt: now)
    #expect(plan.isReady(asOf: now) == true)
}

@Test("plan isReady is true after availableAt")
func planIsReadyAfter() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 10)
    let plan = PurchasePlan(
        title: "Camera",
        amount: 8_000_000,
        availableAt: now.addingTimeInterval(-1)
    )
    #expect(plan.isReady(asOf: now) == true)
}

@Test("plan uses default category, period and status")
func planDefaults() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1)
    let plan = PurchasePlan(title: "Thing", amount: 100, availableAt: now)
    #expect(plan.category == .other)
    #expect(plan.coolingPeriod == .threeDays)
    #expect(plan.status == .waiting)
    #expect(plan.note == nil)
    #expect(plan.decisionAt == nil)
}

@Test("plan round-trips through Codable")
func planCodableRoundTrip() throws {
    let now = try makeDate(year: 2026, month: 5, day: 1, hour: 8)
    let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let plan = PurchasePlan(
        id: id,
        title: "Console",
        amount: 12_000_000,
        category: .entertainment,
        note: "Birthday",
        coolingPeriod: .twoWeeks,
        status: .approved,
        createdAt: now,
        availableAt: now.addingTimeInterval(14 * 86_400),
        decisionAt: now.addingTimeInterval(15 * 86_400)
    )
    let data = try JSONEncoder().encode(plan)
    let decoded = try JSONDecoder().decode(PurchasePlan.self, from: data)
    #expect(decoded == plan)
}

@Test("plan category exposes nine cases with stable ids and symbols")
func planCategoryMetadata() {
    #expect(PurchasePlanCategory.allCases.count == 9)
    #expect(PurchasePlanCategory.fashion.id == "fashion")
    #expect(PurchasePlanCategory.electronics.symbolName == "iphone")
    #expect(PurchasePlanCategory.other.symbolName == "ellipsis.circle")
    #expect(PurchasePlanCategory.travel.nameKey == "coolingOff.category.travel")
}

@Test("plan category every case has a non-empty symbol and name key")
func planCategoryAllSymbols() {
    for category in PurchasePlanCategory.allCases {
        #expect(category.symbolName.isEmpty == false)
        #expect(category.nameKey == "coolingOff.category.\(category.rawValue)")
        #expect(category.id == category.rawValue)
    }
}

@Test("plan status exposes four cases")
func planStatusCases() {
    #expect(PurchasePlanStatus.allCases.count == 4)
    #expect(Set(PurchasePlanStatus.allCases) == [.waiting, .approved, .cancelled, .expired])
}

@Test("plan status round-trips through Codable")
func planStatusCodableRoundTrip() throws {
    for status in PurchasePlanStatus.allCases {
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(PurchasePlanStatus.self, from: data)
        #expect(decoded == status)
    }
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = fixedCalendar()
) throws -> Date {
    try #require(
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
