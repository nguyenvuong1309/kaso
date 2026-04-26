import Foundation
import Testing
@testable import GoalDomain

@Test("calculates goal progress and clamps completion fraction")
func calculatesGoalProgress() throws {
    let deadline = try date(year: 2026, month: 9, day: 30)
    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 10_000_000,
        currentAmount: 2_500_000,
        deadline: deadline
    )

    #expect(goal.progress.remainingAmount == 7_500_000)
    #expect(goal.progress.fraction == 0.25)
    #expect(goal.progress.percent == 25)
    #expect(goal.progress.isCompleted == false)
    #expect(goal.status(on: try date(year: 2026, month: 4, day: 26)) == .inProgress)

    let overfundedGoal = SavingGoal(
        name: "Trip",
        targetAmount: 5_000_000,
        currentAmount: 6_000_000,
        deadline: deadline
    )

    #expect(overfundedGoal.progress.remainingAmount == 0)
    #expect(overfundedGoal.progress.fraction == 1)
    #expect(overfundedGoal.progress.percent == 100)
    #expect(overfundedGoal.progress.isCompleted)
}

@Test("calculates monthly required saving through deadline month")
func calculatesMonthlyRequiredSaving() throws {
    let calendar = fixedCalendar()
    let goal = SavingGoal(
        name: "Buy a motorbike",
        targetAmount: 12_000_000,
        currentAmount: 3_000_000,
        deadline: try date(year: 2026, month: 9, day: 30)
    )

    let requiredSaving = goal.monthlyRequiredSaving(
        asOf: try date(year: 2026, month: 4, day: 26),
        calendar: calendar
    )

    #expect(requiredSaving == 1_500_000)
}

@Test("returns remaining amount when deadline month already passed")
func returnsRemainingAmountForPassedDeadlineMonth() throws {
    let calendar = fixedCalendar()
    let goal = SavingGoal(
        name: "Laptop",
        targetAmount: 8_000_000,
        currentAmount: 5_000_000,
        deadline: try date(year: 2026, month: 3, day: 31)
    )

    let requiredSaving = goal.monthlyRequiredSaving(
        asOf: try date(year: 2026, month: 4, day: 26),
        calendar: calendar
    )

    #expect(requiredSaving == 3_000_000)
}

@Test("prioritizes completed status before overdue status")
func prioritizesCompletedBeforeOverdue() throws {
    let today = try date(year: 2026, month: 4, day: 26)
    let pastDeadline = try date(year: 2026, month: 3, day: 31)

    let completedGoal = SavingGoal(
        name: "Phone",
        targetAmount: 10_000_000,
        currentAmount: 10_000_000,
        deadline: pastDeadline
    )
    let overdueGoal = SavingGoal(
        name: "Course",
        targetAmount: 6_000_000,
        currentAmount: 4_000_000,
        deadline: pastDeadline
    )

    #expect(completedGoal.status(on: today, calendar: fixedCalendar()) == .completed)
    #expect(overdueGoal.status(on: today, calendar: fixedCalendar()) == .overdue)
}

@Test("estimates delayed days from budget overage")
func estimatesDelayedDaysFromBudgetOverage() throws {
    let calendar = fixedCalendar()
    let today = try date(year: 2026, month: 4, day: 1)
    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 25_000_000,
        deadline: try date(year: 2026, month: 4, day: 30),
        createdAt: try date(year: 2026, month: 1, day: 1)
    )

    let delayedDays = SavingGoalDelayEstimator.delayedDayCount(
        overageAmount: 500_000,
        goal: goal,
        asOf: today,
        calendar: calendar
    )

    #expect(delayedDays == 3)
}

@Test("plans emergency fund target from monthly expense")
func plansEmergencyFundTargetFromMonthlyExpense() throws {
    let recommendation = try #require(
        EmergencyFundPlanner.recommendation(
            monthlyExpense: 10_000_000,
            currentAmount: 15_000_000,
            targetMonthCount: 6,
            buildMonthCount: 12
        )
    )

    #expect(recommendation.recommendedAmount == 60_000_000)
    #expect(recommendation.remainingAmount == 45_000_000)
    #expect(recommendation.coverageMonthCount == 1.5)
    #expect(recommendation.monthlyTopUpAmount == 3_750_000)
}

@Test("projects retirement timeline from savings rate")
func projectsRetirementTimelineFromSavingsRate() throws {
    let simulation = try #require(
        RetirementSimulator.simulate(
            monthlyIncome: 30_000_000,
            monthlyExpense: 10_000_000,
            currentSavings: 100_000_000,
            annualReturnRate: 0,
            targetAnnualExpenseMultiplier: 25
        )
    )

    #expect(simulation.targetAmount == 3_000_000_000)
    #expect(simulation.monthlyContribution == 20_000_000)
    #expect(simulation.projectedMonthCount == 145)
    #expect(simulation.status == .reachable)
}

@Test("validates invalid saving goal drafts")
func validatesInvalidDrafts() throws {
    let today = try date(year: 2026, month: 4, day: 26)
    let invalidDraft = SavingGoalDraft(
        name: "   ",
        targetAmount: 0,
        currentAmount: -1,
        deadline: try date(year: 2026, month: 4, day: 25)
    )

    #expect(
        invalidDraft.validationErrors(asOf: today, calendar: fixedCalendar()) == [
            .nameRequired,
            .targetAmountMustBePositive,
            .currentAmountCannotBeNegative,
            .deadlineMustBeInFuture,
        ]
    )

    let overfundedDraft = SavingGoalDraft(
        name: "Travel",
        targetAmount: 10_000_000,
        currentAmount: 10_000_001,
        deadline: try date(year: 2026, month: 12, day: 31)
    )

    #expect(
        overfundedDraft.validationErrors(asOf: today, calendar: fixedCalendar()) == [
            .currentAmountCannotExceedTargetAmount,
        ]
    )

    do {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        _ = try invalidDraft.validated(
            id: id,
            createdAt: today,
            calendar: fixedCalendar()
        )
        Issue.record("Invalid draft should throw")
    } catch let error as SavingGoalValidationError {
        #expect(error == .nameRequired)
    }
}

@Test("validates and trims valid saving goal drafts")
func validatesAndTrimsDrafts() throws {
    let today = try date(year: 2026, month: 4, day: 26)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let draft = SavingGoalDraft(
        name: "  Emergency fund  ",
        targetAmount: 30_000_000,
        currentAmount: 5_000_000,
        deadline: try date(year: 2026, month: 10, day: 31),
        imageIdentifier: "goal-emergency"
    )

    let goal = try draft.validated(
        id: id,
        createdAt: today,
        calendar: fixedCalendar()
    )

    #expect(goal.id == id)
    #expect(goal.name == "Emergency fund")
    #expect(goal.targetAmount == 30_000_000)
    #expect(goal.currentAmount == 5_000_000)
    #expect(goal.createdAt == today)
    #expect(goal.imageIdentifier == "goal-emergency")
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
