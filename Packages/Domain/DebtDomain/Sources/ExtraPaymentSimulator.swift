import Foundation

public struct ExtraPaymentResult: Equatable, Sendable {
    public var baselineSchedule: AmortizationSchedule
    public var acceleratedSchedule: AmortizationSchedule
    public var monthsSaved: Int
    public var interestSaved: Decimal
    public var newPayoffDate: Date?

    public init(
        baselineSchedule: AmortizationSchedule,
        acceleratedSchedule: AmortizationSchedule,
        monthsSaved: Int,
        interestSaved: Decimal,
        newPayoffDate: Date?
    ) {
        self.baselineSchedule = baselineSchedule
        self.acceleratedSchedule = acceleratedSchedule
        self.monthsSaved = monthsSaved
        self.interestSaved = interestSaved
        self.newPayoffDate = newPayoffDate
    }
}

public enum ExtraPaymentSimulator {
    public static func simulate(
        debt: Debt,
        extraMonthly: Decimal,
        oneTime: Decimal = 0,
        calendar: Calendar = .current
    ) throws -> ExtraPaymentResult {
        let baseline = try AmortizationCalculator.schedule(for: debt, calendar: calendar)
        let accelerated = try AmortizationCalculator.schedule(
            for: debt,
            extraMonthlyPayment: max(extraMonthly, 0),
            oneTimeExtraPayment: max(oneTime, 0),
            calendar: calendar
        )

        let monthsSaved = max(baseline.entries.count - accelerated.entries.count, 0)
        let interestSaved = max(baseline.totalInterest - accelerated.totalInterest, 0)

        return ExtraPaymentResult(
            baselineSchedule: baseline,
            acceleratedSchedule: accelerated,
            monthsSaved: monthsSaved,
            interestSaved: interestSaved,
            newPayoffDate: accelerated.payoffDate
        )
    }
}
