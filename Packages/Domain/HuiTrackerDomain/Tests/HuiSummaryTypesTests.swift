import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiSummaryTypesTests {
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

    @Test("group summary netPosition subtracts contributed from received")
    func groupSummaryNetPosition() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let summary = HuiGroupSummary(
            id: id,
            name: "G",
            totalContributed: 6_000_000,
            totalReceived: 10_000_000,
            paidCycleCount: 3,
            totalCycleCount: 5,
            nextDueDate: nil,
            nextDueIndex: nil
        )
        #expect(summary.netPosition == 4_000_000)
    }

    @Test("group summary isComplete requires non-zero cycles all paid")
    func groupSummaryIsCompleteCases() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C2"))

        let zero = HuiGroupSummary(
            id: id, name: "G", totalContributed: 0, totalReceived: 0,
            paidCycleCount: 0, totalCycleCount: 0, nextDueDate: nil, nextDueIndex: nil
        )
        #expect(zero.isComplete == false)

        let partial = HuiGroupSummary(
            id: id, name: "G", totalContributed: 0, totalReceived: 0,
            paidCycleCount: 2, totalCycleCount: 4, nextDueDate: nil, nextDueIndex: nil
        )
        #expect(partial.isComplete == false)

        let complete = HuiGroupSummary(
            id: id, name: "G", totalContributed: 0, totalReceived: 0,
            paidCycleCount: 4, totalCycleCount: 4, nextDueDate: nil, nextDueIndex: nil
        )
        #expect(complete.isComplete)
    }

    @Test("group summary equality includes next due fields")
    func groupSummaryEquality() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C3"))
        let due = try makeDate(year: 2026, month: 5, day: 1)
        let lhs = HuiGroupSummary(
            id: id, name: "G", totalContributed: 1, totalReceived: 2,
            paidCycleCount: 1, totalCycleCount: 2, nextDueDate: due, nextDueIndex: 2
        )
        let rhs = HuiGroupSummary(
            id: id, name: "G", totalContributed: 1, totalReceived: 2,
            paidCycleCount: 1, totalCycleCount: 2, nextDueDate: due, nextDueIndex: 2
        )
        let different = HuiGroupSummary(
            id: id, name: "G", totalContributed: 1, totalReceived: 2,
            paidCycleCount: 1, totalCycleCount: 2, nextDueDate: due, nextDueIndex: 3
        )
        #expect(lhs == rhs)
        #expect(lhs != different)
    }

    @Test("overall summary default initializer is all zero")
    func overallDefaults() {
        let overall = HuiOverallSummary()
        #expect(overall.totalContributed == 0)
        #expect(overall.totalReceived == 0)
        #expect(overall.activeGroupCount == 0)
        #expect(overall.netPosition == 0)
    }

    @Test("overall summary netPosition subtracts contributed from received")
    func overallNetPosition() {
        let overall = HuiOverallSummary(
            totalContributed: 8_000_000,
            totalReceived: 3_000_000,
            activeGroupCount: 2
        )
        #expect(overall.netPosition == -5_000_000)
    }

    @Test("overall summary equality compares all stored fields")
    func overallEquality() {
        let lhs = HuiOverallSummary(totalContributed: 1, totalReceived: 2, activeGroupCount: 3)
        let rhs = HuiOverallSummary(totalContributed: 1, totalReceived: 2, activeGroupCount: 3)
        let different = HuiOverallSummary(totalContributed: 1, totalReceived: 2, activeGroupCount: 4)
        #expect(lhs == rhs)
        #expect(lhs != different)
    }
}
