import Foundation

public struct DebtSummary: Equatable, Sendable {
    public var totalPrincipalRemaining: Decimal
    public var totalMonthlyPayment: Decimal
    public var totalProjectedInterest: Decimal
    public var debtCount: Int

    public init(
        totalPrincipalRemaining: Decimal,
        totalMonthlyPayment: Decimal,
        totalProjectedInterest: Decimal,
        debtCount: Int
    ) {
        self.totalPrincipalRemaining = totalPrincipalRemaining
        self.totalMonthlyPayment = totalMonthlyPayment
        self.totalProjectedInterest = totalProjectedInterest
        self.debtCount = debtCount
    }

    public static let empty = DebtSummary(
        totalPrincipalRemaining: 0,
        totalMonthlyPayment: 0,
        totalProjectedInterest: 0,
        debtCount: 0
    )
}

public enum DebtSummaryBuilder {
    public static func make(
        debts: [Debt],
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> DebtSummary {
        var totalRemaining: Decimal = 0
        var totalMonthly: Decimal = 0
        var totalInterest: Decimal = 0

        for debt in debts {
            guard let schedule = try? AmortizationCalculator.schedule(for: debt, calendar: calendar) else {
                continue
            }
            totalRemaining += schedule.remainingBalance(asOf: date) ?? debt.principal
            if !schedule.entriesAfter(date).isEmpty {
                totalMonthly += schedule.monthlyPayment
            }
            let remainingInterest = schedule.entriesAfter(date)
                .reduce(Decimal(0)) { $0 + $1.interestPart }
            totalInterest += remainingInterest
        }

        return DebtSummary(
            totalPrincipalRemaining: totalRemaining,
            totalMonthlyPayment: totalMonthly,
            totalProjectedInterest: totalInterest,
            debtCount: debts.count
        )
    }
}
