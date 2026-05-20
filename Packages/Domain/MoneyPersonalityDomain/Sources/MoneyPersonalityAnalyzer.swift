import Foundation

public struct PersonalityTransactionInput: Equatable, Sendable {
    public let amount: Decimal
    public let categoryID: String
    public let isExpense: Bool
    public let occurredAt: Date
    public let weekday: Int  // 1 = Sunday, 7 = Saturday

    public init(amount: Decimal, categoryID: String, isExpense: Bool, occurredAt: Date, calendar: Calendar = .current) {
        self.amount = amount
        self.categoryID = categoryID
        self.isExpense = isExpense
        self.occurredAt = occurredAt
        weekday = calendar.component(.weekday, from: occurredAt)
    }
}

public enum MoneyPersonalityAnalyzer {
    public static let minimumTransactionCount = 30

    public static func analyze(
        transactions: [PersonalityTransactionInput],
        budgetUtilizationRatio: Double = 0.5,
        savingsRate: Double = 0.0,
        analyzedAt: Date = Date()
    ) -> MoneyPersonalityProfile {
        guard transactions.count >= minimumTransactionCount else {
            return MoneyPersonalityProfile.insufficientPlaceholder
        }

        let expenses = transactions.filter(\.isExpense)
        let totalExpense = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        guard totalExpense > 0 else {
            return MoneyPersonalityProfile.insufficientPlaceholder
        }

        let totalExpenseDouble = NSDecimalNumber(decimal: totalExpense).doubleValue
        let categoryShare = categoryShare(expenses: expenses, totalExpense: totalExpenseDouble)

        let foodShare = categoryShare["food"] ?? 0
        let entertainmentShare = (categoryShare["entertainment"] ?? 0) + (categoryShare["travel"] ?? 0)
        let shoppingShare = categoryShare["shopping"] ?? 0
        let weekendShare = computeWeekendShare(expenses: expenses, totalExpense: totalExpenseDouble)
        let largeBurstShare = computeLargeBurstShare(expenses: expenses, totalExpense: totalExpenseDouble)
        let categoryDiversity = computeCategoryDiversity(categoryShare: categoryShare)

        let plannerScore = computePlannerScore(
            budgetUtilizationRatio: budgetUtilizationRatio,
            savingsRate: savingsRate,
            largeBurstShare: largeBurstShare,
            categoryDiversity: categoryDiversity
        )

        let impulsiveScore = computeImpulsiveScore(
            largeBurstShare: largeBurstShare,
            shoppingShare: shoppingShare,
            weekendShare: weekendShare,
            budgetUtilizationRatio: budgetUtilizationRatio
        )

        let minimalistScore = computeMinimalistScore(
            savingsRate: savingsRate,
            categoryDiversity: categoryDiversity,
            totalExpensePerCount: totalExpenseDouble / Double(expenses.count),
            transactionCount: expenses.count
        )

        let foodieScore = max(0.0, min(1.0, foodShare * 2.2))
        let experienceScore = max(0.0, min(1.0, entertainmentShare * 2.5))

        let typeScores: [MoneyPersonalityType: Double] = [
            .planner: plannerScore,
            .impulsive: impulsiveScore,
            .minimalist: minimalistScore,
            .foodie: foodieScore,
            .experienceSeeker: experienceScore,
        ]

        let topType = typeScores.max { $0.value < $1.value }?.key ?? .planner

        let traits = [
            MoneyPersonalityTrait(id: "planning", labelKey: "personality.trait.planning", value: plannerScore),
            MoneyPersonalityTrait(id: "impulse", labelKey: "personality.trait.impulse", value: impulsiveScore),
            MoneyPersonalityTrait(id: "frugality", labelKey: "personality.trait.frugality", value: minimalistScore),
            MoneyPersonalityTrait(id: "food", labelKey: "personality.trait.food", value: foodieScore),
            MoneyPersonalityTrait(id: "experiences", labelKey: "personality.trait.experiences", value: experienceScore),
            MoneyPersonalityTrait(id: "diversity", labelKey: "personality.trait.diversity", value: categoryDiversity),
        ]

        return MoneyPersonalityProfile(
            type: topType,
            typeScores: typeScores,
            traits: traits,
            analyzedTransactionCount: transactions.count,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
    }

    private static func categoryShare(expenses: [PersonalityTransactionInput], totalExpense: Double) -> [String: Double] {
        var share: [String: Double] = [:]
        for expense in expenses {
            let amount = NSDecimalNumber(decimal: expense.amount).doubleValue
            share[expense.categoryID, default: 0] += amount
        }
        return share.mapValues { $0 / totalExpense }
    }

    private static func computeWeekendShare(expenses: [PersonalityTransactionInput], totalExpense: Double) -> Double {
        let weekendTotal = expenses
            .filter { $0.weekday == 1 || $0.weekday == 7 }
            .map { NSDecimalNumber(decimal: $0.amount).doubleValue }
            .reduce(0, +)
        return weekendTotal / totalExpense
    }

    private static func computeLargeBurstShare(expenses: [PersonalityTransactionInput], totalExpense: Double) -> Double {
        let avgPerTransaction = totalExpense / Double(expenses.count)
        let largeThreshold = avgPerTransaction * 3
        let largeBurstTotal = expenses
            .map { NSDecimalNumber(decimal: $0.amount).doubleValue }
            .filter { $0 >= largeThreshold }
            .reduce(0, +)
        return largeBurstTotal / totalExpense
    }

    private static func computeCategoryDiversity(categoryShare: [String: Double]) -> Double {
        // Shannon entropy normalized to 0-1
        let entropy = categoryShare.values.reduce(0.0) { partial, share in
            guard share > 0 else { return partial }
            return partial - share * log(share)
        }
        let maxEntropy = log(Double(max(categoryShare.count, 1)))
        guard maxEntropy > 0 else { return 0 }
        return min(1.0, entropy / maxEntropy)
    }

    private static func computePlannerScore(
        budgetUtilizationRatio: Double,
        savingsRate: Double,
        largeBurstShare: Double,
        categoryDiversity: Double
    ) -> Double {
        // Stay within budget (0.4) + savings (0.3) + low burst (0.2) + moderate diversity (0.1)
        let budgetScore = max(0, 1 - max(0, budgetUtilizationRatio - 0.7) * 2)
        let savingsScore = max(0, min(1, savingsRate * 3))
        let burstScore = max(0, 1 - largeBurstShare * 3)
        let diversityScore = 1 - abs(categoryDiversity - 0.6)
        return budgetScore * 0.4 + savingsScore * 0.3 + burstScore * 0.2 + diversityScore * 0.1
    }

    private static func computeImpulsiveScore(
        largeBurstShare: Double,
        shoppingShare: Double,
        weekendShare: Double,
        budgetUtilizationRatio: Double
    ) -> Double {
        let burstScore = min(1.0, largeBurstShare * 2.5)
        let shoppingScore = min(1.0, shoppingShare * 3.0)
        let weekendScore = min(1.0, max(0, (weekendShare - 0.28) * 4))
        let overspendScore = min(1.0, max(0, (budgetUtilizationRatio - 1.0) * 2))
        return burstScore * 0.35 + shoppingScore * 0.25 + weekendScore * 0.2 + overspendScore * 0.2
    }

    private static func computeMinimalistScore(
        savingsRate: Double,
        categoryDiversity: Double,
        totalExpensePerCount: Double,
        transactionCount: Int
    ) -> Double {
        let savingsScore = min(1.0, savingsRate * 2.5)
        let lowDiversityScore = max(0, 1 - categoryDiversity)
        let lowFrequencyScore: Double = transactionCount < 50 ? 0.8 : transactionCount < 80 ? 0.5 : 0.2
        return savingsScore * 0.5 + lowDiversityScore * 0.3 + lowFrequencyScore * 0.2
    }
}
