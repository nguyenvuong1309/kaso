import Foundation

public enum WhatIfCalculator {
    public static func project(_ scenario: WhatIfScenario) -> WhatIfProjection {
        let effectiveIncome = max(scenario.monthlyIncome + scenario.incomeDelta, 0)
        let effectiveExpenses = max(scenario.monthlyExpenses + scenario.expenseDelta, 0)
        let netSavings = max(effectiveIncome - effectiveExpenses + scenario.additionalSavings, 0)

        let savingsRate: Double = {
            let incomeDouble = NSDecimalNumber(decimal: effectiveIncome).doubleValue
            guard incomeDouble > 0 else {
                return 0
            }
            return NSDecimalNumber(decimal: netSavings).doubleValue / incomeDouble
        }()

        let monthlyRate = scenario.annualInvestmentReturnRate / 12.0
        var balance = Decimal(0)
        var totalInterest = Decimal(0)
        var totalContributions = Decimal(0)
        var balances: [Decimal] = []
        var monthsToGoal: Int?
        let horizon = max(scenario.horizonMonths, 0)

        for month in 1 ... max(horizon, 1) {
            if monthlyRate > 0 {
                let balanceDouble = NSDecimalNumber(decimal: balance).doubleValue
                let interest = balanceDouble * monthlyRate
                totalInterest += Decimal(interest)
                balance += Decimal(interest)
            }
            balance += netSavings
            totalContributions += netSavings
            if balances.count < horizon {
                balances.append(balance)
            }
            if let goal = scenario.goalAmount, balance >= goal, monthsToGoal == nil {
                monthsToGoal = month
            }
            if month >= horizon {
                break
            }
        }

        return WhatIfProjection(
            effectiveMonthlyIncome: effectiveIncome,
            effectiveMonthlyExpenses: effectiveExpenses,
            monthlyNetSavings: netSavings,
            savingsRate: savingsRate,
            endingBalance: balances.last ?? balance,
            totalSaved: totalContributions,
            totalInterestEarned: totalInterest,
            monthsToGoal: monthsToGoal,
            monthlyBalances: balances
        )
    }

    public static func breakdownToHitGoal(
        _ scenario: WhatIfScenario,
        maxMonths: Int = 600
    ) -> Int? {
        guard let goal = scenario.goalAmount, goal > 0 else {
            return nil
        }
        var extended = scenario
        extended.horizonMonths = maxMonths
        return project(extended).monthsToGoal
    }
}
