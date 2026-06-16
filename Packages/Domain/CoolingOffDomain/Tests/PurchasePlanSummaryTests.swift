import Foundation
import Testing
@testable import CoolingOffDomain

@Test("summary empty has no plans and zero totals")
func summaryEmptyConstant() {
    let summary = PurchasePlanSummary.empty
    #expect(summary.waiting.isEmpty)
    #expect(summary.ready.isEmpty)
    #expect(summary.decided.isEmpty)
    #expect(summary.totalWaitingAmount == 0)
    #expect(summary.totalAvoidedAmount == 0)
}

@Test("summary builder on empty input returns empty summary")
func summaryBuilderEmptyInput() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let summary = PurchasePlanSummaryBuilder.build(plans: [], referenceDate: now)
    #expect(summary == .empty)
}

@Test("summary waiting list is sorted by availableAt ascending")
func summaryWaitingSorted() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let later = PurchasePlan(
        title: "Later",
        amount: 1_000_000,
        status: .waiting,
        createdAt: now,
        availableAt: now.addingTimeInterval(5 * 86_400)
    )
    let sooner = PurchasePlan(
        title: "Sooner",
        amount: 1_000_000,
        status: .waiting,
        createdAt: now,
        availableAt: now.addingTimeInterval(2 * 86_400)
    )
    let summary = PurchasePlanSummaryBuilder.build(plans: [later, sooner], referenceDate: now)
    #expect(summary.waiting.map(\.title) == ["Sooner", "Later"])
}

@Test("summary pending total includes both waiting and ready plans")
func summaryPendingTotalIncludesReady() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let waiting = PurchasePlan(
        title: "Waiting",
        amount: 2_000_000,
        status: .waiting,
        createdAt: now,
        availableAt: now.addingTimeInterval(86_400)
    )
    let ready = PurchasePlan(
        title: "Ready",
        amount: 3_000_000,
        status: .waiting,
        createdAt: now.addingTimeInterval(-2 * 86_400),
        availableAt: now.addingTimeInterval(-86_400)
    )
    let summary = PurchasePlanSummaryBuilder.build(plans: [waiting, ready], referenceDate: now)
    #expect(summary.waiting.map(\.id) == [waiting.id])
    #expect(summary.ready.map(\.id) == [ready.id])
    #expect(summary.totalWaitingAmount == 5_000_000)
}

@Test("summary avoided total counts cancelled and expired but not approved")
func summaryAvoidedTotal() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let approved = PurchasePlan(
        title: "Approved",
        amount: 1_000_000,
        status: .approved,
        createdAt: now.addingTimeInterval(-5 * 86_400),
        availableAt: now.addingTimeInterval(-4 * 86_400),
        decisionAt: now.addingTimeInterval(-3 * 86_400)
    )
    let cancelled = PurchasePlan(
        title: "Cancelled",
        amount: 2_000_000,
        status: .cancelled,
        createdAt: now.addingTimeInterval(-6 * 86_400),
        availableAt: now.addingTimeInterval(-5 * 86_400),
        decisionAt: now.addingTimeInterval(-2 * 86_400)
    )
    let expired = PurchasePlan(
        title: "Expired",
        amount: 4_000_000,
        status: .expired,
        createdAt: now.addingTimeInterval(-7 * 86_400),
        availableAt: now.addingTimeInterval(-6 * 86_400),
        decisionAt: now.addingTimeInterval(-86_400)
    )
    let summary = PurchasePlanSummaryBuilder.build(
        plans: [approved, cancelled, expired],
        referenceDate: now
    )
    #expect(summary.totalAvoidedAmount == 6_000_000)
    #expect(summary.totalWaitingAmount == 0)
    #expect(Set(summary.decided.map(\.id)) == [approved.id, cancelled.id, expired.id])
}

@Test("summary decided list is sorted by decisionAt descending")
func summaryDecidedSortedByDecision() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let oldest = PurchasePlan(
        title: "Oldest",
        amount: 1_000_000,
        status: .approved,
        createdAt: now.addingTimeInterval(-10 * 86_400),
        availableAt: now.addingTimeInterval(-9 * 86_400),
        decisionAt: now.addingTimeInterval(-8 * 86_400)
    )
    let newest = PurchasePlan(
        title: "Newest",
        amount: 1_000_000,
        status: .cancelled,
        createdAt: now.addingTimeInterval(-5 * 86_400),
        availableAt: now.addingTimeInterval(-4 * 86_400),
        decisionAt: now.addingTimeInterval(-86_400)
    )
    let summary = PurchasePlanSummaryBuilder.build(plans: [oldest, newest], referenceDate: now)
    #expect(summary.decided.map(\.title) == ["Newest", "Oldest"])
}

@Test("summary decided plans missing decisionAt sort to the end")
func summaryDecidedNilDecisionLast() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let withDecision = PurchasePlan(
        title: "WithDecision",
        amount: 1_000_000,
        status: .approved,
        createdAt: now.addingTimeInterval(-5 * 86_400),
        availableAt: now.addingTimeInterval(-4 * 86_400),
        decisionAt: now.addingTimeInterval(-86_400)
    )
    let withoutDecision = PurchasePlan(
        title: "WithoutDecision",
        amount: 1_000_000,
        status: .expired,
        createdAt: now.addingTimeInterval(-6 * 86_400),
        availableAt: now.addingTimeInterval(-5 * 86_400),
        decisionAt: nil
    )
    let summary = PurchasePlanSummaryBuilder.build(
        plans: [withoutDecision, withDecision],
        referenceDate: now
    )
    #expect(summary.decided.map(\.title) == ["WithDecision", "WithoutDecision"])
}

@Test("summary waiting plan exactly at referenceDate counts as ready")
func summaryBoundaryReady() throws {
    let now = try makeDate(year: 2026, month: 6, day: 1, hour: 12)
    let atBoundary = PurchasePlan(
        title: "Boundary",
        amount: 1_000_000,
        status: .waiting,
        createdAt: now.addingTimeInterval(-86_400),
        availableAt: now
    )
    let summary = PurchasePlanSummaryBuilder.build(plans: [atBoundary], referenceDate: now)
    #expect(summary.ready.map(\.id) == [atBoundary.id])
    #expect(summary.waiting.isEmpty)
}

@Test("summary value type supports equality")
func summaryEquality() {
    #expect(PurchasePlanSummary.empty == PurchasePlanSummary.empty)
    let nonEmpty = PurchasePlanSummary(
        waiting: [],
        ready: [],
        decided: [],
        totalWaitingAmount: 1,
        totalAvoidedAmount: 0
    )
    #expect(nonEmpty != .empty)
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
