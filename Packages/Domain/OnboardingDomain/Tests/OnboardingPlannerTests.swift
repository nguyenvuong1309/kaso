import Foundation
import Testing
import TransactionDomain
@testable import OnboardingDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
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

@Test("applies the reduceOverspending savings rate of 25 percent")
func plannerReduceOverspendingSavingsRate() throws {
    let date = try makeDate(year: 2026, month: 1, day: 1)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food],
        financialGoal: .reduceOverspending,
        completedAt: date
    )

    #expect(profile.monthlySavingsTarget == Decimal(2_500_000))
    // Single category absorbs the entire remaining budget pool.
    #expect(profile.suggestedBudgets == [BudgetSuggestion(category: .food, monthlyLimit: 7_500_000)])
}

@Test("applies the trackCashflow savings rate of 20 percent")
func plannerTrackCashflowSavingsRate() throws {
    let date = try makeDate(year: 2026, month: 2, day: 15)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.housing],
        financialGoal: .trackCashflow,
        completedAt: date
    )

    #expect(profile.monthlySavingsTarget == Decimal(2_000_000))
    #expect(profile.suggestedBudgets == [BudgetSuggestion(category: .housing, monthlyLimit: 8_000_000)])
}

@Test("applies the saveForPurchase savings rate of 30 percent")
func plannerSaveForPurchaseSavingsRate() throws {
    let date = try makeDate(year: 2026, month: 3, day: 10)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.transport],
        financialGoal: .saveForPurchase,
        completedAt: date
    )

    #expect(profile.monthlySavingsTarget == Decimal(3_000_000))
    #expect(profile.suggestedBudgets == [BudgetSuggestion(category: .transport, monthlyLimit: 7_000_000)])
}

@Test("splits the budget pool across categories by weight")
func plannerWeightedSplitAcrossThreeCategories() throws {
    let date = try makeDate(year: 2026, month: 4, day: 26)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport, .housing],
        financialGoal: .buildEmergencyFund,
        completedAt: date
    )

    // pool = 20M - 30% = 14M; weights food 20, transport 12, housing 35; total 67.
    let pool = Decimal(14_000_000)
    let total = Decimal(67)
    #expect(profile.monthlySavingsTarget == Decimal(6_000_000))
    #expect(
        profile.suggestedBudgets == [
            BudgetSuggestion(category: .food, monthlyLimit: pool * 20 / total),
            BudgetSuggestion(category: .transport, monthlyLimit: pool * 12 / total),
            BudgetSuggestion(category: .housing, monthlyLimit: pool * 35 / total),
        ]
    )
}

@Test("uses the default weight of 10 for categories without a specific weight")
func plannerDefaultWeightForUnmappedCategory() throws {
    let date = try makeDate(year: 2026, month: 5, day: 1)

    // .salary is not mapped in the weight table, so it falls back to weight 10.
    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.salary, .health],
        financialGoal: .trackCashflow,
        completedAt: date
    )

    // pool = 10M - 20% = 8M; salary default weight 10, health weight 10; total 20.
    let pool = Decimal(8_000_000)
    let total = Decimal(20)
    #expect(
        profile.suggestedBudgets == [
            BudgetSuggestion(category: .salary, monthlyLimit: pool * 10 / total),
            BudgetSuggestion(category: .health, monthlyLimit: pool * 10 / total),
        ]
    )
}

@Test("deduplicates repeated categories preserving first-seen order")
func plannerDeduplicatesCategories() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food, .transport, .food, .transport, .food],
        financialGoal: .trackCashflow,
        completedAt: date
    )

    #expect(profile.primaryCategories == [.food, .transport])
    #expect(profile.suggestedBudgets.map(\.category) == [.food, .transport])
}

@Test("rejects negative monthly income")
func plannerRejectsNegativeIncome() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)
    #expect(throws: OnboardingValidationError.monthlyIncomeMustBePositive) {
        try OnboardingPlanner.makeProfile(
            monthlyIncome: -1,
            primaryCategories: [.food],
            financialGoal: .trackCashflow,
            completedAt: date
        )
    }
}

@Test("treats a category list of only duplicates as a single valid category")
func plannerDuplicateOnlyListIsValid() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food, .food, .food],
        financialGoal: .trackCashflow,
        completedAt: date
    )

    #expect(profile.primaryCategories == [.food])
}

@Test("preserves the completion date on the resulting profile")
func plannerPreservesCompletionDate() throws {
    let date = try makeDate(year: 2026, month: 7, day: 4, hour: 9)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 5_000_000,
        primaryCategories: [.food],
        financialGoal: .buildEmergencyFund,
        completedAt: date
    )

    #expect(profile.completedAt == date)
    #expect(profile.financialGoal == .buildEmergencyFund)
}

@Test("budget suggestion limits sum to the post-savings pool")
func plannerBudgetSumEqualsPool() throws {
    let date = try makeDate(year: 2026, month: 8, day: 8)

    let profile = try OnboardingPlanner.makeProfile(
        monthlyIncome: 12_000_000,
        primaryCategories: [.food, .transport, .housing, .health],
        financialGoal: .trackCashflow,
        completedAt: date
    )

    let pool = profile.monthlyIncome - profile.monthlySavingsTarget
    let sum = profile.suggestedBudgets.reduce(Decimal(0)) { $0 + $1.monthlyLimit }
    #expect(sum == pool)
}
