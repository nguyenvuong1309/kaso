import Foundation

public enum SavingGoalDelayEstimator {
    public static func delayedDayCount(
        overageAmount: Decimal,
        goal: SavingGoal,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let monthlyRequiredSaving = goal.monthlyRequiredSaving(asOf: date, calendar: calendar)
        guard overageAmount > 0, monthlyRequiredSaving > 0 else {
            return 0
        }

        var delayedDays = overageAmount * 30 / monthlyRequiredSaving
        var roundedDelayedDays = Decimal()
        NSDecimalRound(&roundedDelayedDays, &delayedDays, 0, .up)
        return max(NSDecimalNumber(decimal: roundedDelayedDays).intValue, 1)
    }
}
