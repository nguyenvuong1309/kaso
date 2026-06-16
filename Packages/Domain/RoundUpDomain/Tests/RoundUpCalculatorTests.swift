import Foundation
import Testing
@testable import RoundUpDomain

// MARK: - roundedUp

@Test("roundedUp returns amount unchanged for non-positive amount")
func roundedUpNonPositiveAmount() {
    #expect(RoundUpCalculator.roundedUp(amount: 0, step: .tenThousand) == 0)
    #expect(RoundUpCalculator.roundedUp(amount: -5_000, step: .tenThousand) == -5_000)
}

@Test("roundedUp handles fractional amounts below a step")
func roundedUpFractionalAmount() {
    #expect(RoundUpCalculator.roundedUp(amount: 1, step: .oneThousand) == 1_000)
    #expect(RoundUpCalculator.roundedUp(amount: 500, step: .oneThousand) == 1_000)
    #expect(RoundUpCalculator.roundedUp(amount: 999, step: .oneThousand) == 1_000)
}

@Test("roundedUp pushes exact multiples to the next boundary across all steps")
func roundedUpExactMultiplesAllSteps() {
    #expect(RoundUpCalculator.roundedUp(amount: 5_000, step: .fiveThousand) == 10_000)
    #expect(RoundUpCalculator.roundedUp(amount: 50_000, step: .fiftyThousand) == 100_000)
    #expect(RoundUpCalculator.roundedUp(amount: 100_000, step: .fiftyThousand) == 150_000)
}

@Test("roundedUp on large amount rounds to next step")
func roundedUpLargeAmount() {
    #expect(RoundUpCalculator.roundedUp(amount: 1_234_567, step: .tenThousand) == 1_240_000)
    #expect(RoundUpCalculator.roundedUp(amount: 1_234_567, step: .fiftyThousand) == 1_250_000)
}

// MARK: - contribution

@Test("contribution is difference to next step when no cap")
func contributionWithoutCap() {
    let rule = RoundUpRule(isEnabled: true, step: .tenThousand)
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: rule) == 5_000)
    #expect(RoundUpCalculator.contribution(amount: 91_000, rule: rule) == 9_000)
}

@Test("contribution returns full diff when diff is below cap")
func contributionBelowCap() {
    let rule = RoundUpRule(
        isEnabled: true,
        step: .tenThousand,
        maxContributionPerTransaction: 8_000
    )
    // 85_000 -> 90_000, diff 5_000 < cap 8_000
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: rule) == 5_000)
}

@Test("contribution returns diff when diff equals cap exactly")
func contributionEqualsCap() {
    let rule = RoundUpRule(
        isEnabled: true,
        step: .tenThousand,
        maxContributionPerTransaction: 5_000
    )
    // diff 5_000 == cap 5_000, not greater, so returns diff
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: rule) == 5_000)
}

@Test("contribution ignores cap when cap is zero or negative")
func contributionIgnoresNonPositiveCap() {
    let zeroCap = RoundUpRule(
        isEnabled: true,
        step: .tenThousand,
        maxContributionPerTransaction: 0
    )
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: zeroCap) == 5_000)

    let negativeCap = RoundUpRule(
        isEnabled: true,
        step: .tenThousand,
        maxContributionPerTransaction: -10
    )
    #expect(RoundUpCalculator.contribution(amount: 85_000, rule: negativeCap) == 5_000)
}

@Test("contribution is zero for negative amount on enabled rule")
func contributionNegativeAmount() {
    let rule = RoundUpRule(isEnabled: true, step: .tenThousand)
    #expect(RoundUpCalculator.contribution(amount: -1, rule: rule) == 0)
}

// MARK: - entry

@Test("entry uses provided id, createdAt and metadata")
func entryUsesProvidedMetadata() throws {
    let id = try #require(UUID(uuidString: "99999999-9999-9999-9999-999999999999"))
    let txnID = try #require(UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"))
    let goalID = try #require(UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"))
    let created = try makeDate(year: 2026, month: 5, day: 20)

    let rule = RoundUpRule(
        isEnabled: true,
        step: .tenThousand,
        linkedSavingGoalID: goalID
    )

    let entry = try #require(
        RoundUpCalculator.entry(
            amount: 85_000,
            rule: rule,
            sourceTransactionID: txnID,
            note: "lunch",
            id: id,
            createdAt: created
        )
    )

    #expect(entry.id == id)
    #expect(entry.sourceTransactionID == txnID)
    #expect(entry.note == "lunch")
    #expect(entry.createdAt == created)
    #expect(entry.step == .tenThousand)
    #expect(entry.savingGoalID == goalID)
    #expect(entry.roundedAmount == 90_000)
    #expect(entry.contribution == 5_000)
}

@Test("entry roundedAmount equals original plus contribution when capped")
func entryCappedRoundedAmount() throws {
    let rule = RoundUpRule(
        isEnabled: true,
        step: .fiftyThousand,
        maxContributionPerTransaction: 10_000
    )
    // 5_000 -> 50_000 diff 45_000, capped to 10_000
    let entry = try #require(RoundUpCalculator.entry(amount: 5_000, rule: rule))
    #expect(entry.contribution == 10_000)
    #expect(entry.roundedAmount == 15_000)
    #expect(entry.originalAmount == 5_000)
}

@Test("entry is nil for non-positive amount")
func entryNilForNonPositiveAmount() {
    let rule = RoundUpRule(isEnabled: true, step: .tenThousand)
    #expect(RoundUpCalculator.entry(amount: 0, rule: rule) == nil)
    #expect(RoundUpCalculator.entry(amount: -100, rule: rule) == nil)
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var calendar = calendar
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return try #require(
        DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
