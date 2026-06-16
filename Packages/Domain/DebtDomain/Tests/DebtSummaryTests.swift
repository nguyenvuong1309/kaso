import Foundation
import Testing
@testable import DebtDomain

@Suite("DebtSummary")
struct DebtSummaryTests {
    @Test("empty constant is all zeros")
    func emptyConstant() {
        let summary = DebtSummary.empty
        #expect(summary.totalPrincipalRemaining == 0)
        #expect(summary.totalMonthlyPayment == 0)
        #expect(summary.totalProjectedInterest == 0)
        #expect(summary.debtCount == 0)
    }

    @Test("builder on empty list returns zeros but counts nothing")
    func builderEmptyList() throws {
        let summary = DebtSummaryBuilder.make(
            debts: [],
            asOf: try makeDate(year: 2026, month: 1, day: 1),
            calendar: makeCalendar()
        )
        #expect(summary == DebtSummary.empty)
    }

    @Test("debtCount counts all debts including invalid ones")
    func debtCountIncludesInvalid() throws {
        let valid = makeDebt(termMonths: 12)
        let invalid = makeDebt(termMonths: 0)
        let summary = DebtSummaryBuilder.make(
            debts: [valid, invalid],
            asOf: try makeDate(year: 2026, month: 1, day: 1),
            calendar: makeCalendar()
        )
        // Both debts counted, but only the valid one contributes to totals.
        #expect(summary.debtCount == 2)
        #expect(summary.totalPrincipalRemaining == 12_000_000)
    }

    @Test("after final payoff there is no monthly payment or future interest")
    func afterPayoffNoMonthly() throws {
        let debt = makeDebt(termMonths: 6, annualInterestRatePercent: 0)
        let summary = DebtSummaryBuilder.make(
            debts: [debt],
            asOf: try makeDate(year: 2027, month: 1, day: 1),
            calendar: makeCalendar()
        )
        #expect(summary.totalMonthlyPayment == 0)
        #expect(summary.totalProjectedInterest == 0)
        #expect(summary.totalPrincipalRemaining == 0)
    }

    @Test("monthly payment is summed only for debts with future entries")
    func monthlyPaymentSummedForActiveDebts() throws {
        let active = makeDebt(termMonths: 24, annualInterestRatePercent: 12)
        let paidOff = makeDebt(termMonths: 3, annualInterestRatePercent: 12)
        let asOf = try makeDate(year: 2026, month: 6, day: 1)
        let summary = DebtSummaryBuilder.make(
            debts: [active, paidOff],
            asOf: asOf,
            calendar: makeCalendar()
        )
        let activeSchedule = try AmortizationCalculator.schedule(for: active, calendar: makeCalendar())
        #expect(summary.totalMonthlyPayment == activeSchedule.monthlyPayment)
    }

    @Test("projected interest equals sum of future interest parts")
    func projectedInterestMatchesFutureEntries() throws {
        let debt = makeDebt(termMonths: 12, annualInterestRatePercent: 18)
        let asOf = try makeDate(year: 2026, month: 4, day: 1)
        let summary = DebtSummaryBuilder.make(
            debts: [debt],
            asOf: asOf,
            calendar: makeCalendar()
        )
        let schedule = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        let expected = schedule.entriesAfter(asOf).reduce(Decimal(0)) { $0 + $1.interestPart }
        #expect(summary.totalProjectedInterest == expected)
        #expect(summary.totalProjectedInterest > 0)
    }

    private func makeDebt(
        termMonths: Int,
        annualInterestRatePercent: Decimal = 0,
        principal: Decimal = 12_000_000
    ) -> Debt {
        Debt(
            name: "Vay",
            type: .personalLoan,
            principal: principal,
            annualInterestRatePercent: annualInterestRatePercent,
            termMonths: termMonths,
            startDate: fixedStart(),
            paymentDay: 1
        )
    }

    private func fixedStart() -> Date {
        DateComponents(calendar: makeCalendar(), year: 2026, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 0)
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
