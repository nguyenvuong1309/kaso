import Foundation

public enum GuiltFreeBudgetCalculator {
    public static func calculate(_ config: GuiltFreeBudgetConfiguration) -> GuiltFreeBudget {
        let income = max(config.monthlyIncome, 0)
        let fixedCosts = config.fixedCosts.reduce(Decimal(0)) { $0 + max($1.amount, 0) }
        let savings = max(config.monthlySavingsTarget, 0)
        let emergency = max(config.emergencyFundMonthlyContribution, 0)
        let allocated = fixedCosts + savings + emergency
        let freeMoney = income - allocated

        let incomeDouble = NSDecimalNumber(decimal: income).doubleValue
        let freeMoneyDouble = NSDecimalNumber(decimal: freeMoney).doubleValue
        let fixedDouble = NSDecimalNumber(decimal: fixedCosts).doubleValue
        let savingsDouble = NSDecimalNumber(decimal: savings + emergency).doubleValue

        let freeRatio = incomeDouble > 0 ? freeMoneyDouble / incomeDouble : 0
        let fixedRatio = incomeDouble > 0 ? fixedDouble / incomeDouble : 0
        let savingsRatio = incomeDouble > 0 ? savingsDouble / incomeDouble : 0

        let health: GuiltFreeBudgetHealth
        if income <= 0 {
            health = .incomeMissing
        } else if freeMoney < 0 {
            health = .overspending
        } else if freeRatio < 0.1 {
            health = .tight
        } else {
            health = .healthy
        }

        return GuiltFreeBudget(
            monthlyIncome: income,
            totalFixedCosts: fixedCosts,
            totalSavings: savings,
            totalEmergency: emergency,
            freeMoney: freeMoney,
            health: health,
            freeMoneyRatio: freeRatio,
            fixedCostsRatio: fixedRatio,
            savingsRatio: savingsRatio
        )
    }

    public static func dailyAllowance(
        from budget: GuiltFreeBudget,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        guard budget.freeMoney > 0 else {
            return 0
        }
        let remaining = remainingDaysInMonth(asOf: referenceDate, calendar: calendar)
        guard remaining > 0 else {
            return budget.freeMoney
        }
        return budget.freeMoney / Decimal(remaining)
    }

    private static func remainingDaysInMonth(asOf date: Date, calendar: Calendar) -> Int {
        guard
            let range = calendar.range(of: .day, in: .month, for: date),
            let day = calendar.dateComponents([.day], from: date).day
        else {
            return 1
        }
        return max(range.count - day + 1, 1)
    }
}
