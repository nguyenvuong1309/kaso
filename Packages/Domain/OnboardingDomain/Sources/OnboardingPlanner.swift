import Foundation
import TransactionDomain

public enum OnboardingValidationError: Error, Equatable, Sendable {
    case monthlyIncomeMustBePositive
    case primaryCategoriesRequired
}

public enum OnboardingPlanner {
    public static func makeProfile(
        monthlyIncome: Decimal,
        primaryCategories: [TransactionCategory],
        financialGoal: FinancialGoal,
        completedAt: Date
    ) throws -> OnboardingProfile {
        guard monthlyIncome > Decimal(0) else {
            throw OnboardingValidationError.monthlyIncomeMustBePositive
        }

        let categories = unique(primaryCategories)
        guard categories.isEmpty == false else {
            throw OnboardingValidationError.primaryCategoriesRequired
        }

        let monthlySavingsTarget = monthlyIncome
            * financialGoal.savingsRatePercent
            / Decimal(100)
        let budgetPool = monthlyIncome - monthlySavingsTarget
        let suggestedBudgets = budgetSuggestions(
            budgetPool: budgetPool,
            categories: categories
        )

        return OnboardingProfile(
            monthlyIncome: monthlyIncome,
            primaryCategories: categories,
            financialGoal: financialGoal,
            monthlySavingsTarget: monthlySavingsTarget,
            suggestedBudgets: suggestedBudgets,
            completedAt: completedAt
        )
    }

    private static func budgetSuggestions(
        budgetPool: Decimal,
        categories: [TransactionCategory]
    ) -> [BudgetSuggestion] {
        let totalWeight = categories.reduce(Decimal(0)) {
            $0 + weight(for: $1)
        }

        return categories.map { category in
            BudgetSuggestion(
                category: category,
                monthlyLimit: budgetPool * weight(for: category) / totalWeight
            )
        }
    }

    private static func unique(
        _ categories: [TransactionCategory]
    ) -> [TransactionCategory] {
        var seenCategoryIDs: Set<String> = []
        return categories.filter { category in
            seenCategoryIDs.insert(category.id).inserted
        }
    }

    private static func weight(for category: TransactionCategory) -> Decimal {
        switch category.id {
        case TransactionCategory.housing.id:
            35
        case TransactionCategory.food.id:
            20
        case TransactionCategory.transport.id:
            12
        case TransactionCategory.health.id:
            10
        case TransactionCategory.education.id:
            8
        case TransactionCategory.shopping.id:
            8
        case TransactionCategory.entertainment.id:
            7
        default:
            10
        }
    }
}
