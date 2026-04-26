import Foundation
import Testing
@testable import DebtDomain
@testable import WealthDomain

@Test("computes amortization schedule with positive interest rate")
func amortizationWithInterest() throws {
    let debt = Debt(
        name: "Vay mua nhà",
        type: .mortgage,
        principal: 1_000_000_000,
        annualInterestRatePercent: 12,
        termMonths: 240,
        startDate: try fixedDate(year: 2026, month: 1, day: 1),
        paymentDay: 1
    )

    let schedule = try AmortizationCalculator.schedule(for: debt, calendar: fixedCalendar())

    #expect(schedule.entries.count == 240)
    #expect(schedule.monthlyPayment > 0)
    #expect(schedule.totalInterest > 0)
    #expect(schedule.entries.last?.remainingBalance == 0)
    #expect(schedule.payoffDate != nil)
    let lastEntry = try #require(schedule.entries.last)
    #expect(lastEntry.period == 240)
}

@Test("zero interest schedule splits principal evenly")
func amortizationZeroInterest() throws {
    let debt = Debt(
        name: "Mượn bạn",
        type: .personalLoan,
        principal: 12_000_000,
        annualInterestRatePercent: 0,
        termMonths: 12,
        startDate: try fixedDate(year: 2026, month: 1, day: 15),
        paymentDay: 15
    )

    let schedule = try AmortizationCalculator.schedule(for: debt, calendar: fixedCalendar())

    #expect(schedule.entries.count == 12)
    #expect(schedule.monthlyPayment == 1_000_000)
    #expect(schedule.totalInterest == 0)
    #expect(schedule.entries.last?.remainingBalance == 0)
}

@Test("invalid principal or term throws")
func amortizationInvalidInput() throws {
    let zeroPrincipal = Debt(
        name: "Bug",
        type: .other,
        principal: 0,
        annualInterestRatePercent: 5,
        termMonths: 12,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )
    let zeroTerm = Debt(
        name: "Bug",
        type: .other,
        principal: 1_000_000,
        annualInterestRatePercent: 5,
        termMonths: 0,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )

    #expect(throws: AmortizationCalculatorError.self) {
        _ = try AmortizationCalculator.schedule(for: zeroPrincipal, calendar: fixedCalendar())
    }
    #expect(throws: AmortizationCalculatorError.self) {
        _ = try AmortizationCalculator.schedule(for: zeroTerm, calendar: fixedCalendar())
    }
}

@Test("payment day clamps to month length")
func paymentDayClamps() throws {
    let debt = Debt(
        name: "Vay nhà",
        type: .mortgage,
        principal: 100_000_000,
        annualInterestRatePercent: 6,
        termMonths: 3,
        startDate: try fixedDate(year: 2026, month: 1, day: 31),
        paymentDay: 31
    )

    let schedule = try AmortizationCalculator.schedule(for: debt, calendar: fixedCalendar())
    let calendar = fixedCalendar()
    let februaryEntry = try #require(schedule.entries.first { calendar.component(.month, from: $0.dueDate) == 2 })

    let day = calendar.component(.day, from: februaryEntry.dueDate)
    #expect(day <= 29)
}

@Test("extra payment simulator reduces months and interest")
func simulatorReducesMonths() throws {
    let debt = Debt(
        name: "Mua xe",
        type: .autoLoan,
        principal: 600_000_000,
        annualInterestRatePercent: 9,
        termMonths: 60,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )

    let result = try ExtraPaymentSimulator.simulate(
        debt: debt,
        extraMonthly: 5_000_000,
        calendar: fixedCalendar()
    )

    #expect(result.acceleratedSchedule.entries.count < result.baselineSchedule.entries.count)
    #expect(result.monthsSaved > 0)
    #expect(result.interestSaved > 0)
}

@Test("simulator with zero extra returns baseline-equivalent schedule")
func simulatorZeroExtraNoSavings() throws {
    let debt = Debt(
        name: "Vay tiêu dùng",
        type: .personalLoan,
        principal: 200_000_000,
        annualInterestRatePercent: 8,
        termMonths: 36,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )

    let result = try ExtraPaymentSimulator.simulate(
        debt: debt,
        extraMonthly: 0,
        calendar: fixedCalendar()
    )

    #expect(result.monthsSaved == 0)
    #expect(result.interestSaved == 0)
    #expect(result.acceleratedSchedule.entries.count == result.baselineSchedule.entries.count)
}

@Test("debt converts to liability with remaining balance")
func debtToLiability() throws {
    let debt = Debt(
        name: "Mua nhà",
        type: .mortgage,
        principal: 1_000_000_000,
        annualInterestRatePercent: 8,
        termMonths: 240,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )

    let asOf = try fixedDate(year: 2027, month: 1, day: 1)
    let liability = debt.toLiability(asOf: asOf, calendar: fixedCalendar())

    #expect(liability.id == debt.id)
    #expect(liability.type == .mortgage)
    #expect(liability.isAutoTracked)
    #expect(liability.principalRemaining < debt.principal)
    #expect(liability.principalRemaining > 0)
}

@Test("debt summary aggregates remaining principal, monthly payment and projected interest")
func debtSummaryAggregates() throws {
    let debt1 = Debt(
        name: "A",
        type: .personalLoan,
        principal: 100_000_000,
        annualInterestRatePercent: 0,
        termMonths: 10,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )
    let debt2 = Debt(
        name: "B",
        type: .creditCard,
        principal: 12_000_000,
        annualInterestRatePercent: 24,
        termMonths: 12,
        startDate: try fixedDate(year: 2026, month: 1, day: 1)
    )

    let summary = DebtSummaryBuilder.make(
        debts: [debt1, debt2],
        asOf: try fixedDate(year: 2026, month: 1, day: 1),
        calendar: fixedCalendar()
    )

    #expect(summary.debtCount == 2)
    #expect(summary.totalPrincipalRemaining == 112_000_000)
    #expect(summary.totalMonthlyPayment > 0)
    #expect(summary.totalProjectedInterest > 0)
}

@Test("debt draft validation reports all errors")
func debtDraftValidation() throws {
    let draft = DebtDraft(
        name: "  ",
        type: .other,
        principal: 0,
        annualInterestRatePercent: -1,
        termMonths: 0,
        startDate: try fixedDate(year: 2026, month: 1, day: 1),
        paymentDay: 0
    )

    #expect(
        Set(draft.validationErrors()) == Set([
            .nameRequired,
            .principalMustBePositive,
            .annualInterestRateCannotBeNegative,
            .termMonthsMustBePositive,
            .paymentDayOutOfRange,
        ])
    )
}

@Test("debt draft rejects term longer than max term months")
func debtDraftRejectsTermTooLong() throws {
    let draft = DebtDraft(
        name: "Lifetime debt",
        type: .other,
        principal: 1_000_000,
        annualInterestRatePercent: 1,
        termMonths: DebtDraft.maxTermMonths + 1,
        startDate: try fixedDate(year: 2026, month: 1, day: 1),
        paymentDay: 1
    )

    #expect(draft.validationErrors().contains(.termMonthsTooLong))
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func fixedDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
