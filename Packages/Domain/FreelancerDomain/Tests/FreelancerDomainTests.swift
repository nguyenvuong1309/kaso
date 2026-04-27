import Foundation
import Testing
@testable import FreelancerDomain

@Test("smoothed income averages the selected rolling window")
func smoothedIncomeAveragesSelectedWindow() {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 10_000_000),
            income(year: 2026, month: 2, gross: 12_000_000),
            income(year: 2026, month: 3, gross: 14_000_000),
            income(year: 2026, month: 4, gross: 50_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 18_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: .threeMonths,
        asOf: date(year: 2026, month: 4, day: 10)
    )

    #expect(view.smoothedMonthlyIncome == Decimal(76_000_000) / 3)
    #expect(view.bufferTarget == view.smoothedMonthlyIncome * 2)
    #expect(view.currentMonthSurplus == 50_000_000 - view.smoothedMonthlyIncome)
    #expect(view.currentMonthDeficit == 0)
    #expect(view.taxProvision == view.smoothedMonthlyIncome * Decimal(0.1))
}

@Test("buffer coverage uses buffer balance over smoothed income")
func bufferCoverageUsesBalanceOverSmoothedIncome() {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 3, gross: 12_000_000),
            income(year: 2026, month: 4, gross: 12_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 6_000_000,
        bufferTargetMultiplier: 3,
        workType: .onlineSeller,
        taxRate: nil
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: .threeMonths,
        asOf: date(year: 2026, month: 4, day: 20)
    )

    #expect(view.bufferCoverage == 0.5)
    #expect(view.bufferStatus == .danger)
}

@Test("deficit appears only when current month is below smoothed income")
func deficitOnlyWhenCurrentMonthBelowSmoothedIncome() {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 30_000_000),
            income(year: 2026, month: 2, gross: 30_000_000),
            income(year: 2026, month: 3, gross: 30_000_000),
            income(year: 2026, month: 4, gross: 6_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 45_000_000,
        bufferTargetMultiplier: 2,
        workType: .gigDriver,
        taxRate: nil
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: .threeMonths,
        asOf: date(year: 2026, month: 4, day: 15)
    )

    #expect(view.currentMonthSurplus == 0)
    #expect(view.currentMonthDeficit == 16_000_000)
}

@Test("reminders include low buffer and tax provision")
func remindersIncludeLowBufferAndTaxProvision() {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 4, gross: 18_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 5_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: FreelancerIncomeSmoother.compute(
            profile: profile,
            window: .threeMonths,
            asOf: date(year: 2026, month: 4, day: 8)
        ),
        asOf: date(year: 2026, month: 4, day: 8)
    )

    #expect(reminders.contains { reminder in
        switch reminder {
        case .lowBuffer:
            true
        default:
            false
        }
    })
    #expect(reminders.contains { reminder in
        switch reminder {
        case .taxDeadline:
            true
        default:
            false
        }
    })
}

private func income(
    year: Int,
    month: Int,
    gross: Decimal,
    deductions: [IncomeDeduction] = []
) -> MonthlyIncome {
    MonthlyIncome(
        month: YearMonth(year: year, month: month),
        grossAmount: gross,
        deductions: deductions
    )
}

private func date(year: Int, month: Int, day: Int) -> Date {
    DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: year,
        month: month,
        day: day
    ).date ?? Date(timeIntervalSinceReferenceDate: 0)
}
