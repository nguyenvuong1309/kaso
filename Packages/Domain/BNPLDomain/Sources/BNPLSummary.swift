import Foundation

public enum BNPLHealth: String, Codable, Equatable, Sendable {
    case safe          // ratio < 10%
    case caution       // 10% - 20%
    case overexposed   // 20% - 30%
    case critical      // > 30%

    public var nameKey: String { "bnpl.health.\(rawValue)" }

    public static func evaluate(monthlyObligation: Decimal, monthlyIncome: Decimal) -> BNPLHealth {
        guard monthlyIncome > 0 else { return .critical }
        let ratio = NSDecimalNumber(decimal: monthlyObligation / monthlyIncome).doubleValue
        if ratio < 0.10 { return .safe }
        if ratio < 0.20 { return .caution }
        if ratio < 0.30 { return .overexposed }
        return .critical
    }
}

public struct BNPLMonthlyExposure: Identifiable, Equatable, Sendable {
    public let id: String  // "yyyy-MM"
    public let year: Int
    public let month: Int
    public var totalDue: Decimal
    public var installmentCount: Int

    public init(year: Int, month: Int, totalDue: Decimal, installmentCount: Int) {
        id = String(format: "%04d-%02d", year, month)
        self.year = year
        self.month = month
        self.totalDue = totalDue
        self.installmentCount = installmentCount
    }
}

public struct BNPLSummary: Equatable, Sendable {
    public var totalActiveObligations: Int
    public var totalOutstanding: Decimal
    public var currentMonthDue: Decimal
    public var nextThreeMonthsDue: Decimal
    public var overdueAmount: Decimal
    public var health: BNPLHealth
    public var exposureRatio: Double  // currentMonthDue / monthlyIncome
    public var monthlyExposures: [BNPLMonthlyExposure]
    public var nextInstallmentDate: Date?

    public init(
        totalActiveObligations: Int,
        totalOutstanding: Decimal,
        currentMonthDue: Decimal,
        nextThreeMonthsDue: Decimal,
        overdueAmount: Decimal,
        health: BNPLHealth,
        exposureRatio: Double,
        monthlyExposures: [BNPLMonthlyExposure],
        nextInstallmentDate: Date?
    ) {
        self.totalActiveObligations = totalActiveObligations
        self.totalOutstanding = totalOutstanding
        self.currentMonthDue = currentMonthDue
        self.nextThreeMonthsDue = nextThreeMonthsDue
        self.overdueAmount = overdueAmount
        self.health = health
        self.exposureRatio = exposureRatio
        self.monthlyExposures = monthlyExposures
        self.nextInstallmentDate = nextInstallmentDate
    }
}

public enum BNPLSummaryBuilder {
    public static func build(
        obligations: [BNPLObligation],
        monthlyIncome: Decimal,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> BNPLSummary {
        let active = obligations.filter { $0.status(at: referenceDate) != .completed }
        let totalOutstanding = active.reduce(Decimal(0)) { $0 + $1.remainingAmount }

        let unpaidInstallments = active.flatMap { obligation in
            obligation.installments
                .filter { $0.isPaid == false }
                .map { (obligation: obligation, installment: $0) }
        }

        guard
            let currentMonth = calendar.dateInterval(of: .month, for: referenceDate),
            let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: currentMonth.start)
        else {
            return empty(active: active, totalOutstanding: totalOutstanding)
        }

        let currentMonthDue = unpaidInstallments
            .filter { currentMonth.contains($0.installment.dueDate) }
            .reduce(Decimal(0)) { $0 + $1.installment.amount }

        let nextThreeMonthsDue = unpaidInstallments
            .filter { $0.installment.dueDate >= currentMonth.start && $0.installment.dueDate < threeMonthsLater }
            .reduce(Decimal(0)) { $0 + $1.installment.amount }

        let overdueAmount = unpaidInstallments
            .filter { $0.installment.dueDate < referenceDate }
            .reduce(Decimal(0)) { $0 + $1.installment.amount }

        let exposureRatio: Double = {
            guard monthlyIncome > 0 else { return 0 }
            return NSDecimalNumber(decimal: currentMonthDue / monthlyIncome).doubleValue
        }()

        let monthlyExposures = computeMonthlyExposures(
            installments: unpaidInstallments,
            from: currentMonth.start,
            monthCount: 6,
            calendar: calendar
        )

        let nextDate = unpaidInstallments
            .map(\.installment.dueDate)
            .filter { $0 >= referenceDate }
            .min()

        return BNPLSummary(
            totalActiveObligations: active.count,
            totalOutstanding: totalOutstanding,
            currentMonthDue: currentMonthDue,
            nextThreeMonthsDue: nextThreeMonthsDue,
            overdueAmount: overdueAmount,
            health: BNPLHealth.evaluate(monthlyObligation: currentMonthDue, monthlyIncome: monthlyIncome),
            exposureRatio: exposureRatio,
            monthlyExposures: monthlyExposures,
            nextInstallmentDate: nextDate
        )
    }

    private static func empty(active: [BNPLObligation], totalOutstanding: Decimal) -> BNPLSummary {
        BNPLSummary(
            totalActiveObligations: active.count,
            totalOutstanding: totalOutstanding,
            currentMonthDue: 0,
            nextThreeMonthsDue: 0,
            overdueAmount: 0,
            health: .safe,
            exposureRatio: 0,
            monthlyExposures: [],
            nextInstallmentDate: nil
        )
    }

    private static func computeMonthlyExposures(
        installments: [(obligation: BNPLObligation, installment: BNPLInstallment)],
        from startDate: Date,
        monthCount: Int,
        calendar: Calendar
    ) -> [BNPLMonthlyExposure] {
        (0 ..< monthCount).compactMap { offset in
            guard
                let monthStart = calendar.date(byAdding: .month, value: offset, to: startDate),
                let interval = calendar.dateInterval(of: .month, for: monthStart)
            else {
                return nil
            }
            let year = calendar.component(.year, from: monthStart)
            let month = calendar.component(.month, from: monthStart)
            let monthInstallments = installments.filter { interval.contains($0.installment.dueDate) }
            return BNPLMonthlyExposure(
                year: year,
                month: month,
                totalDue: monthInstallments.reduce(Decimal(0)) { $0 + $1.installment.amount },
                installmentCount: monthInstallments.count
            )
        }
    }
}
