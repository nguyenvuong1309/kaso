import Foundation
import Testing
@testable import FreelancerDomain

private let testCalendar = Calendar(identifier: .gregorian)

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = testCalendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
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

// MARK: - compute window selection

@Test("compute falls back to profile smoothing window when none passed")
func computeUsesProfileWindow() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 6_000_000),
            income(year: 2026, month: 2, gross: 6_000_000),
            income(year: 2026, month: 3, gross: 6_000_000),
            income(year: 2026, month: 4, gross: 60_000_000),
        ],
        smoothingWindow: .sixMonths,
        bufferBalance: 0,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 10),
        calendar: testCalendar
    )

    #expect(view.window == .sixMonths)
    #expect(view.smoothedMonthlyIncome == Decimal(78_000_000) / 4)
}

@Test("compute passed window overrides profile window")
func computeOverrideWindow() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 9_000_000)],
        smoothingWindow: .twelveMonths,
        workType: .freelancer
    )
    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: .threeMonths,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )
    #expect(view.window == .threeMonths)
}

// MARK: - eligibility / filtering

@Test("compute excludes future months from the smoothing window")
func computeExcludesFutureMonths() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 3, gross: 10_000_000),
            income(year: 2026, month: 4, gross: 10_000_000),
            income(year: 2026, month: 5, gross: 90_000_000),
        ],
        smoothingWindow: .threeMonths,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        window: .threeMonths,
        asOf: try makeDate(year: 2026, month: 4, day: 15),
        calendar: testCalendar
    )

    // Only March + April are eligible; May is in the future.
    #expect(view.smoothedMonthlyIncome == 10_000_000)
    #expect(view.currentMonthNetIncome == 10_000_000)
}

@Test("compute returns zeros when there are no eligible incomes")
func computeEmptyIncomes() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [],
        smoothingWindow: .threeMonths,
        bufferBalance: 5_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )

    #expect(view.smoothedMonthlyIncome == 0)
    #expect(view.currentMonthNetIncome == 0)
    #expect(view.bufferTarget == 0)
    #expect(view.taxProvision == 0)
    #expect(view.currentMonthSurplus == 0)
    #expect(view.currentMonthDeficit == 0)
    #expect(view.bufferCoverage == 0)
    #expect(view.bufferStatus == .danger)
}

@Test("current month net income is zero when only past months exist")
func computeCurrentMonthMissing() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 12_000_000),
            income(year: 2026, month: 2, gross: 12_000_000),
        ],
        smoothingWindow: .threeMonths,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )

    #expect(view.currentMonthNetIncome == 0)
    #expect(view.smoothedMonthlyIncome == 12_000_000)
    #expect(view.currentMonthDeficit == 12_000_000)
    #expect(view.currentMonthSurplus == 0)
}

// MARK: - buffer status thresholds

@Test("buffer status is warning when coverage between one and target")
func bufferStatusWarning() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 15_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )

    #expect(view.bufferCoverage == 1.5)
    #expect(view.bufferStatus == .warning)
}

@Test("buffer status is healthy when coverage meets target")
func bufferStatusHealthy() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 20_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )

    #expect(view.bufferCoverage == 2)
    #expect(view.bufferStatus == .healthy)
}

@Test("buffer status is danger exactly below one month coverage")
func bufferStatusDangerBoundary() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 9_999_999,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )

    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )

    #expect(view.bufferStatus == .danger)
}

// MARK: - reminders

@Test("reminders are empty when buffer healthy and no tax or slow season")
func remindersEmptyWhenHealthy() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 30_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: nil
    )
    let asOf = try makeDate(year: 2026, month: 4, day: 1)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    #expect(reminders.isEmpty)
}

@Test("low buffer threshold uses min of one and target multiplier")
func lowBufferThresholdClampedToOne() throws {
    // Target multiplier 0.5 -> threshold = min(1, 0.5) = 0.5
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 6_000_000, // coverage 0.6 >= 0.5 -> no low buffer
        bufferTargetMultiplier: 0.5,
        workType: .freelancer
    )
    let asOf = try makeDate(year: 2026, month: 4, day: 1)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    #expect(view.bufferCoverage == 0.6)
    #expect(!reminders.contains { if case .lowBuffer = $0 { true } else { false } })
}

@Test("no tax reminder when tax provision is zero")
func noTaxReminderWhenZero() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 4, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 30_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: nil
    )
    let asOf = try makeDate(year: 2026, month: 4, day: 1)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    #expect(view.taxProvision == 0)
    #expect(!reminders.contains { if case .taxDeadline = $0 { true } else { false } })
}

@Test("tax deadline due date is April 30 of current year when before deadline")
func taxDeadlineBeforeApril() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 3, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 30_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )
    let asOf = try makeDate(year: 2026, month: 3, day: 15)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )

    let dueDate = try #require(reminders.compactMap { reminder -> Date? in
        if case let .taxDeadline(_, due) = reminder { due } else { nil }
    }.first)
    let components = testCalendar.dateComponents([.year, .month, .day], from: dueDate)
    #expect(components.year == 2026)
    #expect(components.month == 4)
    #expect(components.day == 30)
}

@Test("tax deadline rolls to next year when current date is past April 30")
func taxDeadlineRollsToNextYear() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [income(year: 2026, month: 6, gross: 10_000_000)],
        smoothingWindow: .threeMonths,
        bufferBalance: 30_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer,
        taxRate: 0.1
    )
    let asOf = try makeDate(year: 2026, month: 6, day: 1)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )

    let dueDate = try #require(reminders.compactMap { reminder -> Date? in
        if case let .taxDeadline(_, due) = reminder { due } else { nil }
    }.first)
    let components = testCalendar.dateComponents([.year, .month, .day], from: dueDate)
    #expect(components.year == 2027)
    #expect(components.month == 4)
    #expect(components.day == 30)
}

@Test("slow season alert fires when recent average drops below 70 percent")
func slowSeasonAlertFires() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 30_000_000),
            income(year: 2026, month: 2, gross: 30_000_000),
            income(year: 2026, month: 3, gross: 30_000_000),
            income(year: 2026, month: 4, gross: 10_000_000),
            income(year: 2026, month: 5, gross: 10_000_000),
            income(year: 2026, month: 6, gross: 10_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 60_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )
    let asOf = try makeDate(year: 2026, month: 6, day: 15)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    let slowSeason = reminders.compactMap { reminder -> String? in
        if case let .slowSeasonAlert(pattern) = reminder { pattern } else { nil }
    }.first
    #expect(slowSeason == "freelancer.reminder.slowSeason")
}

@Test("slow season alert does not fire below six months of history")
func slowSeasonNeedsSixMonths() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 30_000_000),
            income(year: 2026, month: 2, gross: 30_000_000),
            income(year: 2026, month: 3, gross: 5_000_000),
            income(year: 2026, month: 4, gross: 5_000_000),
            income(year: 2026, month: 5, gross: 5_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 60_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )
    let asOf = try makeDate(year: 2026, month: 5, day: 15)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    #expect(!reminders.contains { if case .slowSeasonAlert = $0 { true } else { false } })
}

@Test("slow season alert does not fire when recent income holds steady")
func slowSeasonNoDropNoAlert() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(year: 2026, month: 1, gross: 20_000_000),
            income(year: 2026, month: 2, gross: 20_000_000),
            income(year: 2026, month: 3, gross: 20_000_000),
            income(year: 2026, month: 4, gross: 19_000_000),
            income(year: 2026, month: 5, gross: 19_000_000),
            income(year: 2026, month: 6, gross: 19_000_000),
        ],
        smoothingWindow: .threeMonths,
        bufferBalance: 60_000_000,
        bufferTargetMultiplier: 2,
        workType: .freelancer
    )
    let asOf = try makeDate(year: 2026, month: 6, day: 15)
    let view = FreelancerIncomeSmoother.compute(profile: profile, asOf: asOf, calendar: testCalendar)

    let reminders = FreelancerIncomeSmoother.reminders(
        for: profile,
        view: view,
        asOf: asOf,
        calendar: testCalendar
    )
    #expect(!reminders.contains { if case .slowSeasonAlert = $0 { true } else { false } })
}

@Test("compute applies deductions to smoothed net income")
func computeUsesNetAfterDeductions() throws {
    let profile = FreelancerProfile(
        monthlyIncomes: [
            income(
                year: 2026,
                month: 4,
                gross: 10_000_000,
                deductions: [IncomeDeduction(title: "Tax", amount: 2_000_000, category: .tax)]
            ),
        ],
        smoothingWindow: .threeMonths,
        workType: .freelancer
    )
    let view = FreelancerIncomeSmoother.compute(
        profile: profile,
        asOf: try makeDate(year: 2026, month: 4, day: 1),
        calendar: testCalendar
    )
    #expect(view.smoothedMonthlyIncome == 8_000_000)
    #expect(view.currentMonthNetIncome == 8_000_000)
}
