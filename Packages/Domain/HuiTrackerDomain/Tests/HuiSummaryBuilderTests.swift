import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiSummaryBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
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

    private func group(
        idSuffix: String,
        name: String = "G",
        contributionAmount: Decimal = 2_000_000,
        cycles: [HuiCycle],
        start: Date
    ) throws -> HuiGroup {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000\(idSuffix)"))
        return HuiGroup(
            id: id,
            name: name,
            organizerName: "Org",
            contributionAmount: contributionAmount,
            periodKind: .monthly,
            memberCount: cycles.count,
            startDate: start,
            cycles: cycles
        )
    }

    @Test("empty group yields zeroed summary with nil next due")
    func emptyGroup() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let group = try group(idSuffix: "B0", cycles: [], start: start)
        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.id == group.id)
        #expect(summary.name == "G")
        #expect(summary.totalContributed == 0)
        #expect(summary.totalReceived == 0)
        #expect(summary.paidCycleCount == 0)
        #expect(summary.totalCycleCount == 0)
        #expect(summary.nextDueDate == nil)
        #expect(summary.nextDueIndex == nil)
        #expect(summary.netPosition == 0)
        #expect(summary.isComplete == false)
    }

    @Test("fully paid group is complete with no next due")
    func fullyPaidGroupIsComplete() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let due1 = try makeDate(year: 2026, month: 1, day: 1)
        let due2 = try makeDate(year: 2026, month: 2, day: 1)
        let cycles = [
            HuiCycle(index: 1, dueDate: due1, isPaid: true),
            HuiCycle(index: 2, dueDate: due2, isPaid: true),
        ]
        let group = try group(idSuffix: "B1", contributionAmount: 1_000_000, cycles: cycles, start: start)
        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.paidCycleCount == 2)
        #expect(summary.totalCycleCount == 2)
        #expect(summary.totalContributed == 2_000_000)
        #expect(summary.nextDueDate == nil)
        #expect(summary.nextDueIndex == nil)
        #expect(summary.isComplete)
    }

    @Test("next due picks earliest unpaid cycle by date not index")
    func nextDuePicksEarliestUnpaid() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let earlyDue = try makeDate(year: 2026, month: 1, day: 5)
        let lateDue = try makeDate(year: 2026, month: 3, day: 5)
        // Cycle index 1 is paid; index 3 has an earlier date than index 2.
        let cycles = [
            HuiCycle(index: 1, dueDate: start, isPaid: true),
            HuiCycle(index: 2, dueDate: lateDue),
            HuiCycle(index: 3, dueDate: earlyDue),
        ]
        let group = try group(idSuffix: "B2", cycles: cycles, start: start)
        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.nextDueIndex == 3)
        #expect(summary.nextDueDate == earlyDue)
    }

    @Test("received cycles sum receivedAmount and treat nil as zero")
    func receivedSumHandlesNil() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let due2 = try makeDate(year: 2026, month: 2, day: 1)
        let due3 = try makeDate(year: 2026, month: 3, day: 1)
        let cycles = [
            HuiCycle(index: 1, dueDate: start, isReceived: true, receivedAmount: 4_000_000),
            // received but with nil amount contributes zero
            HuiCycle(index: 2, dueDate: due2, isReceived: true, receivedAmount: nil),
            HuiCycle(index: 3, dueDate: due3, isReceived: true, receivedAmount: 1_000_000),
        ]
        let group = try group(idSuffix: "B3", cycles: cycles, start: start)
        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.totalReceived == 5_000_000)
    }

    @Test("net position is negative when contributed exceeds received")
    func negativeNetPosition() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = [
            HuiCycle(index: 1, dueDate: start, isPaid: true),
        ]
        let group = try group(idSuffix: "B4", contributionAmount: 3_000_000, cycles: cycles, start: start)
        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.totalContributed == 3_000_000)
        #expect(summary.totalReceived == 0)
        #expect(summary.netPosition == -3_000_000)
    }

    @Test("overall summary of empty groups is all zero")
    func overallEmpty() {
        let overall = HuiSummaryBuilder.overall(from: [])
        #expect(overall.totalContributed == 0)
        #expect(overall.totalReceived == 0)
        #expect(overall.activeGroupCount == 0)
        #expect(overall.netPosition == 0)
    }

    @Test("overall summary aggregates totals and counts only active groups")
    func overallAggregatesActiveOnly() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let due2 = try makeDate(year: 2026, month: 2, day: 1)

        // Active: one paid, one unpaid.
        let active = try group(
            idSuffix: "B5",
            contributionAmount: 1_000_000,
            cycles: [
                HuiCycle(index: 1, dueDate: start, isPaid: true),
                HuiCycle(index: 2, dueDate: due2),
            ],
            start: start
        )
        // Complete: all paid, one received.
        let complete = try group(
            idSuffix: "B6",
            contributionAmount: 2_000_000,
            cycles: [
                HuiCycle(index: 1, dueDate: start, isPaid: true, isReceived: true, receivedAmount: 4_000_000),
                HuiCycle(index: 2, dueDate: due2, isPaid: true),
            ],
            start: start
        )

        let overall = HuiSummaryBuilder.overall(from: [active, complete])

        #expect(overall.totalContributed == 5_000_000)
        #expect(overall.totalReceived == 4_000_000)
        #expect(overall.netPosition == -1_000_000)
        #expect(overall.activeGroupCount == 1)
    }
}
