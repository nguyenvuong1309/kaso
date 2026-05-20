import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiTrackerDomainTests {
    @Test("schedule builder creates one cycle per member spaced monthly")
    func scheduleBuilderMonthly() {
        let calendar = Calendar(identifier: .gregorian)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 4,
            startDate: start,
            periodKind: .monthly,
            calendar: calendar
        )

        #expect(cycles.count == 4)
        #expect(cycles.first?.index == 1)
        #expect(cycles.last?.index == 4)
        #expect(cycles[0].dueDate == start)
        let expectedSecond = calendar.date(byAdding: .month, value: 1, to: start)
        #expect(cycles[1].dueDate == expectedSecond)
    }

    @Test("group summary computes contributed, received and net position")
    func groupSummaryComputesNet() {
        var cycles = HuiCycleScheduleBuilder.build(
            memberCount: 3,
            startDate: Date(timeIntervalSince1970: 0),
            periodKind: .monthly
        )
        cycles[0].isPaid = true
        cycles[1].isPaid = true
        cycles[1].isReceived = true
        cycles[1].receivedAmount = 6_000_000

        let group = HuiGroup(
            name: "Test",
            organizerName: "Org",
            contributionAmount: 2_000_000,
            periodKind: .monthly,
            memberCount: 3,
            startDate: Date(timeIntervalSince1970: 0),
            cycles: cycles
        )

        let summary = HuiSummaryBuilder.group(from: group)

        #expect(summary.totalContributed == 4_000_000)
        #expect(summary.totalReceived == 6_000_000)
        #expect(summary.netPosition == 2_000_000)
        #expect(summary.paidCycleCount == 2)
        #expect(summary.nextDueIndex == 3)
        #expect(summary.isComplete == false)
    }

    @Test("overall summary aggregates active groups")
    func overallSummaryAggregates() {
        let group = HuiGroup(
            name: "A",
            organizerName: "O",
            contributionAmount: 1_000_000,
            periodKind: .weekly,
            memberCount: 2,
            startDate: Date(timeIntervalSince1970: 0),
            cycles: [
                HuiCycle(index: 1, dueDate: Date(timeIntervalSince1970: 0), isPaid: true),
                HuiCycle(index: 2, dueDate: Date(timeIntervalSince1970: 1)),
            ]
        )

        let overall = HuiSummaryBuilder.overall(from: [group])

        #expect(overall.totalContributed == 1_000_000)
        #expect(overall.activeGroupCount == 1)
    }
}
