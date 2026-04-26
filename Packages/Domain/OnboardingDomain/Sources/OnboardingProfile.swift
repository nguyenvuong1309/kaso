import Foundation
import TransactionDomain

public struct OnboardingProfile: Codable, Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var primaryCategories: [TransactionCategory]
    public var financialGoal: FinancialGoal
    public var monthlySavingsTarget: Decimal
    public var suggestedBudgets: [BudgetSuggestion]
    public var completedAt: Date

    public init(
        monthlyIncome: Decimal,
        primaryCategories: [TransactionCategory],
        financialGoal: FinancialGoal,
        monthlySavingsTarget: Decimal,
        suggestedBudgets: [BudgetSuggestion],
        completedAt: Date
    ) {
        self.monthlyIncome = monthlyIncome
        self.primaryCategories = primaryCategories
        self.financialGoal = financialGoal
        self.monthlySavingsTarget = monthlySavingsTarget
        self.suggestedBudgets = suggestedBudgets
        self.completedAt = completedAt
    }
}

public extension OnboardingProfile {
    static let preview = OnboardingProfile(
        monthlyIncome: 20_000_000,
        primaryCategories: [.food, .transport, .housing],
        financialGoal: .buildEmergencyFund,
        monthlySavingsTarget: 6_000_000,
        suggestedBudgets: [
            BudgetSuggestion(category: .food, monthlyLimit: 4_179_104.47761194),
            BudgetSuggestion(category: .transport, monthlyLimit: 2_507_462.68656716),
            BudgetSuggestion(category: .housing, monthlyLimit: 7_313_432.8358209),
        ],
        completedAt: Date(timeIntervalSinceReferenceDate: 0)
    )
}
