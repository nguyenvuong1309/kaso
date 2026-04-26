import Foundation

public enum AmortizationCalculatorError: Error, Equatable, Sendable {
    case invalidTerm
    case invalidPrincipal
}

public enum AmortizationCalculator {
    public static func schedule(
        for debt: Debt,
        extraMonthlyPayment: Decimal = 0,
        oneTimeExtraPayment: Decimal = 0,
        calendar: Calendar = .current
    ) throws -> AmortizationSchedule {
        guard debt.termMonths > 0 else {
            throw AmortizationCalculatorError.invalidTerm
        }
        guard debt.principal > 0 else {
            throw AmortizationCalculatorError.invalidPrincipal
        }

        let basePayment = debt.monthlyPaymentOverride ?? computedMonthlyPayment(
            principal: debt.principal,
            monthlyRate: debt.monthlyInterestRate,
            termMonths: debt.termMonths
        )
        let totalMonthlyPayment = basePayment + max(extraMonthlyPayment, 0)
        let dueDates = paymentDueDates(
            startDate: debt.startDate,
            paymentDay: debt.paymentDay,
            count: debt.termMonths,
            calendar: calendar
        )

        var entries: [AmortizationEntry] = []
        entries.reserveCapacity(debt.termMonths)
        var remaining = debt.principal
        var oneTimeRemaining = max(oneTimeExtraPayment, 0)
        var totalInterestAccum: Decimal = 0
        var totalPaymentAccum: Decimal = 0
        var payoffDate: Date?

        for period in 1 ... debt.termMonths {
            guard remaining > 0 else {
                break
            }
            let dueDate = dueDates[period - 1]
            let interest = roundToCents(remaining * debt.monthlyInterestRate)
            var principalPart = roundToCents(totalMonthlyPayment - interest)
            var actualPayment = totalMonthlyPayment

            if oneTimeRemaining > 0 && period == 1 {
                principalPart += oneTimeRemaining
                actualPayment += oneTimeRemaining
                oneTimeRemaining = 0
            }

            if principalPart <= 0 {
                throw AmortizationCalculatorError.invalidPrincipal
            }

            if period == debt.termMonths || principalPart > remaining {
                principalPart = remaining
                actualPayment = roundToCents(principalPart + interest)
            }

            remaining = roundToCents(remaining - principalPart)
            if remaining < 0 {
                remaining = 0
            }

            totalInterestAccum = roundToCents(totalInterestAccum + interest)
            totalPaymentAccum = roundToCents(totalPaymentAccum + actualPayment)

            entries.append(
                AmortizationEntry(
                    period: period,
                    dueDate: dueDate,
                    payment: actualPayment,
                    principalPart: principalPart,
                    interestPart: interest,
                    remainingBalance: remaining
                )
            )

            if remaining <= 0 {
                payoffDate = dueDate
                break
            }
        }

        if payoffDate == nil {
            payoffDate = entries.last?.dueDate
        }

        return AmortizationSchedule(
            entries: entries,
            monthlyPayment: basePayment,
            totalInterest: totalInterestAccum,
            totalPayment: totalPaymentAccum,
            payoffDate: payoffDate,
            initialPrincipal: debt.principal
        )
    }

    public static func computedMonthlyPayment(
        principal: Decimal,
        monthlyRate: Decimal,
        termMonths: Int
    ) -> Decimal {
        guard termMonths > 0 else {
            return 0
        }

        if monthlyRate <= 0 {
            return roundToCents(principal / Decimal(termMonths))
        }

        let principalDouble = NSDecimalNumber(decimal: principal).doubleValue
        let rateDouble = NSDecimalNumber(decimal: monthlyRate).doubleValue
        let factor = pow(1 + rateDouble, Double(termMonths))
        let payment = principalDouble * rateDouble * factor / (factor - 1)

        return roundToCents(Decimal(payment))
    }

    private static func paymentDueDates(
        startDate: Date,
        paymentDay: Int,
        count: Int,
        calendar: Calendar
    ) -> [Date] {
        var dates: [Date] = []
        dates.reserveCapacity(count)

        for offset in 1 ... count {
            guard let monthDate = calendar.date(byAdding: .month, value: offset, to: startDate) else {
                continue
            }

            let monthRange = calendar.range(of: .day, in: .month, for: monthDate)
            let daysInMonth = monthRange?.count ?? 30
            let safeDay = min(paymentDay, daysInMonth)
            var components = calendar.dateComponents([.year, .month], from: monthDate)
            components.day = safeDay
            if let due = calendar.date(from: components) {
                dates.append(due)
            } else {
                dates.append(monthDate)
            }
        }

        if dates.count < count {
            dates.append(contentsOf: Array(repeating: dates.last ?? startDate, count: count - dates.count))
        }

        return dates
    }

    private static func roundToCents(_ value: Decimal) -> Decimal {
        var rounded = Decimal()
        var copy = value
        NSDecimalRound(&rounded, &copy, 0, .plain)
        return rounded
    }
}
