import Foundation

public struct OpportunityCostInputs: Codable, Equatable, Sendable {
    public var monthlyIncome: Decimal
    public var monthlyExpenses: Decimal
    public var emergencyFundTarget: Decimal
    public var savingGoalRemaining: Decimal?
    public var savingGoalDailyContribution: Decimal?

    public init(
        monthlyIncome: Decimal = 0,
        monthlyExpenses: Decimal = 0,
        emergencyFundTarget: Decimal = 0,
        savingGoalRemaining: Decimal? = nil,
        savingGoalDailyContribution: Decimal? = nil
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyExpenses = monthlyExpenses
        self.emergencyFundTarget = emergencyFundTarget
        self.savingGoalRemaining = savingGoalRemaining
        self.savingGoalDailyContribution = savingGoalDailyContribution
    }

    public static let empty = OpportunityCostInputs()
}

public struct OpportunityCost: Equatable, Sendable {
    public var amount: Decimal
    public var hoursOfWork: Double?
    public var savingGoalDelayDays: Int?
    public var emergencyMonthsCoverage: Double?

    public init(
        amount: Decimal,
        hoursOfWork: Double? = nil,
        savingGoalDelayDays: Int? = nil,
        emergencyMonthsCoverage: Double? = nil
    ) {
        self.amount = amount
        self.hoursOfWork = hoursOfWork
        self.savingGoalDelayDays = savingGoalDelayDays
        self.emergencyMonthsCoverage = emergencyMonthsCoverage
    }
}

public enum OpportunityCostCalculator {
    public static func calculate(
        amount: Decimal,
        inputs: OpportunityCostInputs,
        averageHoursPerMonth: Double = 168
    ) -> OpportunityCost {
        let amountDouble = NSDecimalNumber(decimal: amount).doubleValue
        let incomeDouble = NSDecimalNumber(decimal: inputs.monthlyIncome).doubleValue
        let expensesDouble = NSDecimalNumber(decimal: inputs.monthlyExpenses).doubleValue

        let hours: Double? = if incomeDouble > 0 && averageHoursPerMonth > 0 {
            (amountDouble / incomeDouble) * averageHoursPerMonth
        } else {
            nil
        }

        let goalDelay: Int? = {
            guard
                let remaining = inputs.savingGoalRemaining, remaining > 0,
                let daily = inputs.savingGoalDailyContribution, daily > 0
            else {
                return nil
            }
            let amountAsDouble = amountDouble
            let dailyDouble = NSDecimalNumber(decimal: daily).doubleValue
            guard dailyDouble > 0 else {
                return nil
            }
            return Int((amountAsDouble / dailyDouble).rounded(.up))
        }()

        let emergencyMonths: Double? = if expensesDouble > 0 {
            amountDouble / expensesDouble
        } else {
            nil
        }

        return OpportunityCost(
            amount: amount,
            hoursOfWork: hours,
            savingGoalDelayDays: goalDelay,
            emergencyMonthsCoverage: emergencyMonths
        )
    }
}
