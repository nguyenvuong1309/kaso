import Foundation
import Testing
@testable import DebtDomain

@Suite("AmortizationSchedule")
struct AmortizationScheduleTests {
    @Test("empty schedule has zero totals and nil payoff")
    func emptyConstant() {
        let schedule = AmortizationSchedule.empty
        #expect(schedule.entries.isEmpty)
        #expect(schedule.monthlyPayment == 0)
        #expect(schedule.totalInterest == 0)
        #expect(schedule.totalPayment == 0)
        #expect(schedule.payoffDate == nil)
        #expect(schedule.initialPrincipal == 0)
    }

    @Test("remainingBalance before first due date returns initial principal")
    func remainingBeforeFirstDueDate() throws {
        let schedule = makeSchedule()
        let early = try makeDate(year: 2025, month: 12, day: 1)
        #expect(schedule.remainingBalance(asOf: early) == 1_000_000)
    }

    @Test("remainingBalance on empty schedule returns nil")
    func remainingEmptyReturnsNil() throws {
        let date = try makeDate(year: 2026, month: 6, day: 1)
        #expect(AmortizationSchedule.empty.remainingBalance(asOf: date) == nil)
    }

    @Test("remainingBalance returns balance of last elapsed entry")
    func remainingAfterSecondEntry() throws {
        let schedule = makeSchedule()
        let asOf = try makeDate(year: 2026, month: 2, day: 15)
        #expect(schedule.remainingBalance(asOf: asOf) == 600_000)
    }

    @Test("remainingBalance after final due date returns zero")
    func remainingAfterAllEntries() throws {
        let schedule = makeSchedule()
        let asOf = try makeDate(year: 2026, month: 12, day: 1)
        #expect(schedule.remainingBalance(asOf: asOf) == 0)
    }

    @Test("progressFraction is zero when no principal")
    func progressZeroPrincipal() throws {
        let date = try makeDate(year: 2026, month: 6, day: 1)
        #expect(AmortizationSchedule.empty.progressFraction(asOf: date) == 0)
    }

    @Test("progressFraction at start is zero and at payoff is one")
    func progressBoundaries() throws {
        let schedule = makeSchedule()
        let start = try makeDate(year: 2025, month: 12, day: 1)
        let end = try makeDate(year: 2026, month: 12, day: 1)
        #expect(schedule.progressFraction(asOf: start) == 0)
        #expect(schedule.progressFraction(asOf: end) == 1)
    }

    @Test("progressFraction is partial mid-schedule")
    func progressPartial() throws {
        let schedule = makeSchedule()
        let mid = try makeDate(year: 2026, month: 2, day: 15)
        let fraction = schedule.progressFraction(asOf: mid)
        // Paid 400,000 of 1,000,000 -> 0.4
        #expect(abs(fraction - 0.4) < 0.0001)
    }

    @Test("entriesAfter excludes entries on or before given date")
    func entriesAfterFilters() throws {
        let schedule = makeSchedule()
        let cutoff = try makeDate(year: 2026, month: 1, day: 1)
        let after = schedule.entriesAfter(cutoff)
        #expect(after.count == 2)
        #expect(after.allSatisfy { $0.dueDate > cutoff })
    }

    @Test("entriesAfter returns empty when date past final entry")
    func entriesAfterEmpty() throws {
        let schedule = makeSchedule()
        let late = try makeDate(year: 2027, month: 1, day: 1)
        #expect(schedule.entriesAfter(late).isEmpty)
    }

    @Test("schedule round-trips through Codable")
    func codableRoundTrip() throws {
        let schedule = makeSchedule()
        let data = try JSONEncoder().encode(schedule)
        let decoded = try JSONDecoder().decode(AmortizationSchedule.self, from: data)
        #expect(decoded == schedule)
    }

    @Test("entry round-trips through Codable")
    func entryCodableRoundTrip() throws {
        let entry = AmortizationEntry(
            period: 1,
            dueDate: try makeDate(year: 2026, month: 1, day: 1),
            payment: 100,
            principalPart: 90,
            interestPart: 10,
            remainingBalance: 910
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(AmortizationEntry.self, from: data)
        #expect(decoded == entry)
    }

    private func makeSchedule() -> AmortizationSchedule {
        let dates = scheduleDates()
        let entries = [
            AmortizationEntry(period: 1, dueDate: dates[0], payment: 350_000, principalPart: 200_000, interestPart: 150_000, remainingBalance: 800_000),
            AmortizationEntry(period: 2, dueDate: dates[1], payment: 350_000, principalPart: 200_000, interestPart: 150_000, remainingBalance: 600_000),
            AmortizationEntry(period: 3, dueDate: dates[2], payment: 750_000, principalPart: 600_000, interestPart: 150_000, remainingBalance: 0),
        ]
        return AmortizationSchedule(
            entries: entries,
            monthlyPayment: 350_000,
            totalInterest: 450_000,
            totalPayment: 1_450_000,
            payoffDate: dates[2],
            initialPrincipal: 1_000_000
        )
    }

    private func scheduleDates() -> [Date] {
        let calendar = makeCalendar()
        let raw = [(2026, 1, 1), (2026, 2, 1), (2026, 3, 1)]
        return raw.compactMap {
            DateComponents(calendar: calendar, year: $0.0, month: $0.1, day: $0.2).date
        }
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            DateComponents(
                calendar: makeCalendar(),
                year: year,
                month: month,
                day: day
            ).date
        )
    }
}
