import Foundation
import Testing
@testable import CoolingOffDomain

@Test("policy suggests the highest threshold that fits amount")
func policySuggestsHighestThreshold() {
    let policy = CoolingOffPolicy.default
    #expect(policy.suggestedPeriod(for: 100_000) == .oneDay)
    #expect(policy.suggestedPeriod(for: 500_000) == .oneDay)
    #expect(policy.suggestedPeriod(for: 2_500_000) == .threeDays)
    #expect(policy.suggestedPeriod(for: 6_000_000) == .oneWeek)
    #expect(policy.suggestedPeriod(for: 30_000_000) == .twoWeeks)
}

@Test("draft validates title and amount")
func draftValidatesTitleAndAmount() {
    let invalid = PurchasePlanDraft(title: " ", amount: 0)
    #expect(
        Set(invalid.validationErrors()) == Set([.titleRequired, .amountMustBePositive])
    )
}

@Test("draft validated produces plan with availableAt = now + cooling period")
func draftValidatedProducesPlan() throws {
    let now = try date(2026, 4, 26, 9, 0)
    let draft = PurchasePlanDraft(
        title: "iPhone case",
        amount: 800_000,
        category: .electronics,
        coolingPeriod: .threeDays
    )

    let plan = try draft.validated(now: now)

    #expect(plan.title == "iPhone case")
    #expect(plan.status == .waiting)
    #expect(plan.createdAt == now)
    #expect(plan.availableAt == now.addingTimeInterval(3 * 86_400))
}

@Test("summary buckets plans by status and ready state")
func summaryBucketsByStatus() throws {
    let now = try date(2026, 4, 26, 12, 0)
    let waiting = PurchasePlan(
        title: "Jacket",
        amount: 1_500_000,
        coolingPeriod: .threeDays,
        status: .waiting,
        createdAt: now.addingTimeInterval(-86_400),
        availableAt: now.addingTimeInterval(2 * 86_400)
    )
    let ready = PurchasePlan(
        title: "Headphones",
        amount: 3_500_000,
        coolingPeriod: .threeDays,
        status: .waiting,
        createdAt: now.addingTimeInterval(-4 * 86_400),
        availableAt: now.addingTimeInterval(-86_400)
    )
    let cancelled = PurchasePlan(
        title: "Sneakers",
        amount: 1_200_000,
        coolingPeriod: .oneDay,
        status: .cancelled,
        createdAt: now.addingTimeInterval(-7 * 86_400),
        availableAt: now.addingTimeInterval(-6 * 86_400),
        decisionAt: now.addingTimeInterval(-5 * 86_400)
    )

    let summary = PurchasePlanSummaryBuilder.build(
        plans: [waiting, ready, cancelled],
        referenceDate: now
    )

    #expect(summary.waiting.map(\.id) == [waiting.id])
    #expect(summary.ready.map(\.id) == [ready.id])
    #expect(summary.decided.map(\.id) == [cancelled.id])
    #expect(summary.totalWaitingAmount == 5_000_000)
    #expect(summary.totalAvoidedAmount == 1_200_000)
}

@Test("opportunity cost computes hours of work and goal delay")
func opportunityCostComputesValues() {
    let inputs = OpportunityCostInputs(
        monthlyIncome: 20_000_000,
        monthlyExpenses: 12_000_000,
        savingGoalRemaining: 5_000_000,
        savingGoalDailyContribution: 100_000
    )

    let cost = OpportunityCostCalculator.calculate(amount: 2_000_000, inputs: inputs)

    let hours = try? #require(cost.hoursOfWork)
    #expect(hours.map { abs($0 - 16.8) < 0.001 } ?? false)
    #expect(cost.savingGoalDelayDays == 20)
    let emergency = try? #require(cost.emergencyMonthsCoverage)
    #expect(emergency.map { abs($0 - 0.16666666) < 0.001 } ?? false)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date
    )
}
