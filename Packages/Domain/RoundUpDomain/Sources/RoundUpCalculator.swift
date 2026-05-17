import Foundation

public enum RoundUpCalculator {
    public static func roundedUp(amount: Decimal, step: RoundUpStep) -> Decimal {
        let stepAmount = step.amount
        guard amount > 0, stepAmount > 0 else {
            return amount
        }

        var quotient = Decimal()
        var amountCopy = amount / stepAmount
        NSDecimalRound(&quotient, &amountCopy, 0, .up)

        let result = quotient * stepAmount
        return result <= amount ? result + stepAmount : result
    }

    public static func contribution(amount: Decimal, rule: RoundUpRule) -> Decimal {
        guard rule.isEnabled, amount > 0 else {
            return 0
        }

        let rounded = roundedUp(amount: amount, step: rule.step)
        let diff = rounded - amount
        guard let cap = rule.maxContributionPerTransaction, cap > 0 else {
            return diff
        }

        return diff > cap ? cap : diff
    }

    public static func entry(
        amount: Decimal,
        rule: RoundUpRule,
        sourceTransactionID: UUID? = nil,
        note: String? = nil,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) -> RoundUpEntry? {
        let contribution = contribution(amount: amount, rule: rule)
        guard contribution > 0 else {
            return nil
        }

        let rounded = amount + contribution
        return RoundUpEntry(
            id: id,
            sourceTransactionID: sourceTransactionID,
            originalAmount: amount,
            roundedAmount: rounded,
            contribution: contribution,
            step: rule.step,
            savingGoalID: rule.linkedSavingGoalID,
            note: note,
            createdAt: createdAt
        )
    }
}
