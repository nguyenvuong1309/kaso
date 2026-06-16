import Foundation
import Testing
@testable import DebtDomain

@Suite("AmortizationCalculator")
struct AmortizationCalculatorTests {
    @Test("computedMonthlyPayment returns 0 for non-positive term")
    func computedPaymentZeroTerm() {
        let payment = AmortizationCalculator.computedMonthlyPayment(
            principal: 100_000_000,
            monthlyRate: 0.01,
            termMonths: 0
        )
        #expect(payment == 0)
    }

    @Test("computedMonthlyPayment with zero rate divides principal evenly")
    func computedPaymentZeroRate() {
        let payment = AmortizationCalculator.computedMonthlyPayment(
            principal: 12_000_000,
            monthlyRate: 0,
            termMonths: 12
        )
        #expect(payment == 1_000_000)
    }

    @Test("computedMonthlyPayment with negative rate treats as zero rate")
    func computedPaymentNegativeRate() {
        let payment = AmortizationCalculator.computedMonthlyPayment(
            principal: 12_000_000,
            monthlyRate: -0.05,
            termMonths: 6
        )
        #expect(payment == 2_000_000)
    }

    @Test("computedMonthlyPayment with positive rate exceeds even split")
    func computedPaymentPositiveRate() {
        let evenSplit: Decimal = 100_000_000 / 12
        let payment = AmortizationCalculator.computedMonthlyPayment(
            principal: 100_000_000,
            monthlyRate: 0.01,
            termMonths: 12
        )
        #expect(payment > evenSplit)
    }

    @Test("monthlyPaymentOverride replaces computed base payment")
    func overrideUsedAsBasePayment() throws {
        let debt = Debt(
            name: "Override",
            type: .personalLoan,
            principal: 12_000_000,
            annualInterestRatePercent: 0,
            termMonths: 12,
            startDate: try makeDate(year: 2026, month: 1, day: 1),
            monthlyPaymentOverride: 2_000_000
        )
        let schedule = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        #expect(schedule.monthlyPayment == 2_000_000)
        // Higher payment pays off before the full term.
        #expect(schedule.entries.count < 12)
        #expect(schedule.entries.last?.remainingBalance == 0)
    }

    @Test("oneTimeExtraPayment applies in first period and shortens schedule")
    func oneTimeExtraPaymentShortens() throws {
        let debt = Debt(
            name: "One-time",
            type: .personalLoan,
            principal: 120_000_000,
            annualInterestRatePercent: 12,
            termMonths: 24,
            startDate: try makeDate(year: 2026, month: 1, day: 1)
        )
        let baseline = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        let accelerated = try AmortizationCalculator.schedule(
            for: debt,
            oneTimeExtraPayment: 30_000_000,
            calendar: makeCalendar()
        )
        #expect(accelerated.entries.count < baseline.entries.count)
        let firstPayment = try #require(accelerated.entries.first)
        let firstBaseline = try #require(baseline.entries.first)
        #expect(firstPayment.payment > firstBaseline.payment)
    }

    @Test("negative extra payments are clamped to zero")
    func negativeExtraClamped() throws {
        let debt = Debt(
            name: "Clamp",
            type: .personalLoan,
            principal: 60_000_000,
            annualInterestRatePercent: 6,
            termMonths: 12,
            startDate: try makeDate(year: 2026, month: 1, day: 1)
        )
        let normal = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        let negative = try AmortizationCalculator.schedule(
            for: debt,
            extraMonthlyPayment: -1_000_000,
            oneTimeExtraPayment: -1_000_000,
            calendar: makeCalendar()
        )
        #expect(negative.entries.count == normal.entries.count)
        #expect(negative.totalPayment == normal.totalPayment)
    }

    @Test("single-month term pays off entire principal")
    func singleMonthTerm() throws {
        let debt = Debt(
            name: "Short",
            type: .personalLoan,
            principal: 5_000_000,
            annualInterestRatePercent: 12,
            termMonths: 1,
            startDate: try makeDate(year: 2026, month: 1, day: 1)
        )
        let schedule = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        #expect(schedule.entries.count == 1)
        let entry = try #require(schedule.entries.first)
        #expect(entry.principalPart == 5_000_000)
        #expect(entry.remainingBalance == 0)
        #expect(schedule.payoffDate == entry.dueDate)
    }

    @Test("override too small to cover interest throws invalidPrincipal")
    func overrideBelowInterestThrows() throws {
        let debt = Debt(
            name: "Underwater",
            type: .creditCard,
            principal: 1_000_000_000,
            annualInterestRatePercent: 36,
            termMonths: 60,
            startDate: try makeDate(year: 2026, month: 1, day: 1),
            monthlyPaymentOverride: 1
        )
        #expect(throws: AmortizationCalculatorError.self) {
            _ = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        }
    }

    @Test("totalPayment equals sum of entry payments")
    func totalPaymentConsistency() throws {
        let debt = Debt(
            name: "Sum",
            type: .autoLoan,
            principal: 200_000_000,
            annualInterestRatePercent: 9,
            termMonths: 36,
            startDate: try makeDate(year: 2026, month: 1, day: 1)
        )
        let schedule = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        let sumPayments = schedule.entries.reduce(Decimal(0)) { $0 + $1.payment }
        let sumInterest = schedule.entries.reduce(Decimal(0)) { $0 + $1.interestPart }
        #expect(schedule.totalPayment == sumPayments)
        #expect(schedule.totalInterest == sumInterest)
    }

    @Test("due dates advance one month per period from start date")
    func dueDatesAdvanceMonthly() throws {
        let calendar = makeCalendar()
        let debt = Debt(
            name: "Dates",
            type: .personalLoan,
            principal: 30_000_000,
            annualInterestRatePercent: 0,
            termMonths: 3,
            startDate: try makeDate(year: 2026, month: 1, day: 10),
            paymentDay: 10
        )
        let schedule = try AmortizationCalculator.schedule(for: debt, calendar: calendar)
        let months = schedule.entries.map { calendar.component(.month, from: $0.dueDate) }
        #expect(months == [2, 3, 4])
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
