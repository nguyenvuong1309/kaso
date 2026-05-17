import Foundation
import Testing
@testable import RoundUpDomain

@Test("rounds amount up to next step boundary")
func roundsAmountUpToNextStep() {
    #expect(RoundUpCalculator.roundedUp(amount: 85_000, step: .tenThousand) == 90_000)
    #expect(RoundUpCalculator.roundedUp(amount: 85_000, step: .oneThousand) == 86_000)
    #expect(RoundUpCalculator.roundedUp(amount: 85_000, step: .fiftyThousand) == 100_000)
    #expect(RoundUpCalculator.roundedUp(amount: 32_500, step: .fiveThousand) == 35_000)
}

@Test("rounded amount of exact multiple jumps to next step")
func roundedAmountOfExactMultipleJumps() {
    #expect(RoundUpCalculator.roundedUp(amount: 50_000, step: .tenThousand) == 60_000)
    #expect(RoundUpCalculator.roundedUp(amount: 10_000, step: .oneThousand) == 11_000)
}

@Test("contribution is zero when rule disabled or amount non-positive")
func contributionZeroWhenDisabledOrZero() {
    let disabled = RoundUpRule(isEnabled: false, step: .tenThousand)
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: disabled) == 0)

    let enabled = RoundUpRule(isEnabled: true, step: .tenThousand)
    #expect(RoundUpCalculator.contribution(amount: 0, rule: enabled) == 0)
}

@Test("contribution caps at max per transaction")
func contributionCapsAtMax() {
    let rule = RoundUpRule(
        isEnabled: true,
        step: .fiftyThousand,
        maxContributionPerTransaction: 10_000
    )

    let contribution = RoundUpCalculator.contribution(amount: 5_000, rule: rule)
    #expect(contribution == 10_000)
}

@Test("entry is nil when contribution is zero")
func entryNilWhenContributionZero() {
    let disabled = RoundUpRule(isEnabled: false, step: .tenThousand)
    let entry = RoundUpCalculator.entry(amount: 85_000, rule: disabled)
    #expect(entry == nil)
}

@Test("entry captures original, rounded and contribution amounts")
func entryCapturesAmounts() throws {
    let rule = RoundUpRule(isEnabled: true, step: .tenThousand)
    let entry = try #require(
        RoundUpCalculator.entry(amount: 85_000, rule: rule)
    )

    #expect(entry.originalAmount == 85_000)
    #expect(entry.roundedAmount == 90_000)
    #expect(entry.contribution == 5_000)
}

@Test("summary aggregates monthly and lifetime totals")
func summaryAggregatesMonthlyAndLifetime() throws {
    let april = try date(2026, 4, 10)
    let march = try date(2026, 3, 10)
    let entries = [
        RoundUpEntry(
            originalAmount: 85_000,
            roundedAmount: 90_000,
            contribution: 5_000,
            step: .tenThousand,
            createdAt: april
        ),
        RoundUpEntry(
            originalAmount: 32_500,
            roundedAmount: 35_000,
            contribution: 2_500,
            step: .fiveThousand,
            createdAt: april
        ),
        RoundUpEntry(
            originalAmount: 200_000,
            roundedAmount: 250_000,
            contribution: 50_000,
            step: .fiftyThousand,
            createdAt: march
        ),
    ]

    let summary = RoundUpJarSummaryBuilder.summary(
        entries: entries,
        referenceDate: april,
        calendar: fixedCalendar()
    )

    #expect(summary.totalContribution == 57_500)
    #expect(summary.monthlyContribution == 7_500)
    #expect(summary.monthlyEntryCount == 2)
    #expect(summary.lifetimeEntryCount == 3)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
