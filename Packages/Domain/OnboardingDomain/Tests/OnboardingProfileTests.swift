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

@Test("stores all values passed to the initializer")
func onboardingProfileInitStoresValues() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)
    let budgets = [BudgetSuggestion(category: .food, monthlyLimit: 4_000_000)]

    let profile = OnboardingProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food],
        financialGoal: .reduceOverspending,
        monthlySavingsTarget: 2_500_000,
        suggestedBudgets: budgets,
        completedAt: date
    )

    #expect(profile.monthlyIncome == Decimal(10_000_000))
    #expect(profile.primaryCategories == [.food])
    #expect(profile.financialGoal == .reduceOverspending)
    #expect(profile.monthlySavingsTarget == Decimal(2_500_000))
    #expect(profile.suggestedBudgets == budgets)
    #expect(profile.completedAt == date)
}

@Test("equality distinguishes profiles by every stored field")
func onboardingProfileEquality() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)
    let base = OnboardingProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food],
        financialGoal: .trackCashflow,
        monthlySavingsTarget: 2_000_000,
        suggestedBudgets: [BudgetSuggestion(category: .food, monthlyLimit: 8_000_000)],
        completedAt: date
    )

    #expect(base == base)

    var differentGoal = base
    differentGoal.financialGoal = .buildEmergencyFund
    #expect(base != differentGoal)

    var differentIncome = base
    differentIncome.monthlyIncome = 11_000_000
    #expect(base != differentIncome)
}

@Test("round-trips through Codable preserving every field")
func onboardingProfileCodableRoundTrip() throws {
    let date = try makeDate(year: 2026, month: 6, day: 16, hour: 12)
    let profile = OnboardingProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport, .housing],
        financialGoal: .saveForPurchase,
        monthlySavingsTarget: 6_000_000,
        suggestedBudgets: [
            BudgetSuggestion(category: .food, monthlyLimit: 4_179_104.47761194),
            BudgetSuggestion(category: .transport, monthlyLimit: 2_507_462.68656716),
            BudgetSuggestion(category: .housing, monthlyLimit: 7_313_432.8358209),
        ],
        completedAt: date
    )

    let data = try JSONEncoder().encode(profile)
    let decoded = try JSONDecoder().decode(OnboardingProfile.self, from: data)
    #expect(decoded == profile)
}

@Test("preview profile exposes consistent sample values")
func onboardingProfilePreviewValues() {
    let preview = OnboardingProfile.preview
    #expect(preview.monthlyIncome == Decimal(20_000_000))
    #expect(preview.primaryCategories == [.food, .transport, .housing])
    #expect(preview.financialGoal == .buildEmergencyFund)
    #expect(preview.monthlySavingsTarget == Decimal(6_000_000))
    #expect(preview.suggestedBudgets.count == 3)
    #expect(preview.completedAt == Date(timeIntervalSinceReferenceDate: 0))
}
