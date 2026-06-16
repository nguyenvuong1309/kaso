import Foundation
import Testing
@testable import DebtDomain

@Suite("ExtraPaymentSimulator")
struct ExtraPaymentSimulatorTests {
    @Test("one-time payment alone reduces interest and months")
    func oneTimeOnly() throws {
        let debt = makeDebt(principal: 200_000_000, annualInterestRatePercent: 12, termMonths: 36)
        let result = try ExtraPaymentSimulator.simulate(
            debt: debt,
            extraMonthly: 0,
            oneTime: 50_000_000,
            calendar: makeCalendar()
        )
        #expect(result.monthsSaved > 0)
        #expect(result.interestSaved > 0)
        #expect(result.acceleratedSchedule.entries.count < result.baselineSchedule.entries.count)
        #expect(result.newPayoffDate == result.acceleratedSchedule.payoffDate)
    }

    @Test("combined extra monthly and one-time payments accelerate payoff")
    func combinedExtras() throws {
        let debt = makeDebt(principal: 500_000_000, annualInterestRatePercent: 10, termMonths: 60)
        let onlyMonthly = try ExtraPaymentSimulator.simulate(
            debt: debt,
            extraMonthly: 3_000_000,
            oneTime: 0,
            calendar: makeCalendar()
        )
        let combined = try ExtraPaymentSimulator.simulate(
            debt: debt,
            extraMonthly: 3_000_000,
            oneTime: 20_000_000,
            calendar: makeCalendar()
        )
        #expect(combined.monthsSaved >= onlyMonthly.monthsSaved)
        #expect(combined.interestSaved >= onlyMonthly.interestSaved)
    }

    @Test("negative extra inputs are clamped, yielding no savings")
    func negativeInputsClamped() throws {
        let debt = makeDebt(principal: 100_000_000, annualInterestRatePercent: 6, termMonths: 24)
        let result = try ExtraPaymentSimulator.simulate(
            debt: debt,
            extraMonthly: -10_000_000,
            oneTime: -10_000_000,
            calendar: makeCalendar()
        )
        #expect(result.monthsSaved == 0)
        #expect(result.interestSaved == 0)
        #expect(result.acceleratedSchedule.entries.count == result.baselineSchedule.entries.count)
    }

    @Test("simulate propagates calculator errors for invalid debt")
    func invalidDebtThrows() throws {
        let debt = makeDebt(principal: 0, annualInterestRatePercent: 5, termMonths: 12)
        #expect(throws: AmortizationCalculatorError.self) {
            _ = try ExtraPaymentSimulator.simulate(
                debt: debt,
                extraMonthly: 1_000_000,
                calendar: makeCalendar()
            )
        }
    }

    @Test("baseline schedule matches direct calculator output")
    func baselineMatchesCalculator() throws {
        let debt = makeDebt(principal: 80_000_000, annualInterestRatePercent: 9, termMonths: 18)
        let result = try ExtraPaymentSimulator.simulate(
            debt: debt,
            extraMonthly: 2_000_000,
            calendar: makeCalendar()
        )
        let direct = try AmortizationCalculator.schedule(for: debt, calendar: makeCalendar())
        #expect(result.baselineSchedule == direct)
    }

    @Test("result is Equatable across identical simulations")
    func resultEquatable() throws {
        let debt = makeDebt(principal: 40_000_000, annualInterestRatePercent: 7, termMonths: 12)
        let a = try ExtraPaymentSimulator.simulate(debt: debt, extraMonthly: 1_000_000, calendar: makeCalendar())
        let b = try ExtraPaymentSimulator.simulate(debt: debt, extraMonthly: 1_000_000, calendar: makeCalendar())
        #expect(a == b)
    }

    private func makeDebt(
        principal: Decimal,
        annualInterestRatePercent: Decimal,
        termMonths: Int
    ) -> Debt {
        Debt(
            name: "Vay",
            type: .autoLoan,
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
}
