import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiCycleScheduleBuilderTests {
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

    @Test("returns empty array when member count is zero")
    func zeroMembers() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 0,
            startDate: start,
            periodKind: .monthly,
            calendar: calendar
        )
        #expect(cycles.isEmpty)
    }

    @Test("returns empty array for negative member count")
    func negativeMembers() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: -3,
            startDate: start,
            periodKind: .weekly,
            calendar: calendar
        )
        #expect(cycles.isEmpty)
    }

    @Test("single member yields one cycle at the start date")
    func singleMember() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 1,
            startDate: start,
            periodKind: .monthly,
            calendar: calendar
        )
        #expect(cycles.count == 1)
        #expect(cycles[0].index == 1)
        #expect(cycles[0].dueDate == start)
    }

    @Test("weekly schedule spaces cycles by seven days")
    func weeklySpacing() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 3,
            startDate: start,
            periodKind: .weekly,
            calendar: calendar
        )
        #expect(cycles.count == 3)
        let secondExpected = try makeDate(year: 2026, month: 1, day: 8)
        let thirdExpected = try makeDate(year: 2026, month: 1, day: 15)
        #expect(cycles[1].dueDate == secondExpected)
        #expect(cycles[2].dueDate == thirdExpected)
    }

    @Test("biweekly schedule spaces cycles by fourteen days")
    func biweeklySpacing() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 3,
            startDate: start,
            periodKind: .biweekly,
            calendar: calendar
        )
        let secondExpected = try makeDate(year: 2026, month: 1, day: 15)
        let thirdExpected = try makeDate(year: 2026, month: 1, day: 29)
        #expect(cycles[1].dueDate == secondExpected)
        #expect(cycles[2].dueDate == thirdExpected)
    }

    @Test("monthly schedule spaces cycles by one month across year boundary")
    func monthlyAcrossYearBoundary() throws {
        let start = try makeDate(year: 2026, month: 11, day: 30)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 3,
            startDate: start,
            periodKind: .monthly,
            calendar: calendar
        )
        let secondExpected = try makeDate(year: 2026, month: 12, day: 30)
        let thirdExpected = try makeDate(year: 2027, month: 1, day: 30)
        #expect(cycles[1].dueDate == secondExpected)
        #expect(cycles[2].dueDate == thirdExpected)
    }

    @Test("indices are sequential starting at one")
    func sequentialIndices() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 5,
            startDate: start,
            periodKind: .weekly,
            calendar: calendar
        )
        #expect(cycles.map(\.index) == [1, 2, 3, 4, 5])
    }

    @Test("generated cycles start unpaid and unreceived")
    func generatedCyclesAreUnset() throws {
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let cycles = HuiCycleScheduleBuilder.build(
            memberCount: 2,
            startDate: start,
            periodKind: .monthly,
            calendar: calendar
        )
        #expect(cycles.allSatisfy { $0.isPaid == false })
        #expect(cycles.allSatisfy { $0.isReceived == false })
        #expect(cycles.allSatisfy { $0.receivedAmount == nil })
    }
}
