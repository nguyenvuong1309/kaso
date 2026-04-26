import Foundation

public struct AmortizationEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var period: Int
    public var dueDate: Date
    public var payment: Decimal
    public var principalPart: Decimal
    public var interestPart: Decimal
    public var remainingBalance: Decimal

    public init(
        id: UUID = UUID(),
        period: Int,
        dueDate: Date,
        payment: Decimal,
        principalPart: Decimal,
        interestPart: Decimal,
        remainingBalance: Decimal
    ) {
        self.id = id
        self.period = period
        self.dueDate = dueDate
        self.payment = payment
        self.principalPart = principalPart
        self.interestPart = interestPart
        self.remainingBalance = remainingBalance
    }
}

public struct AmortizationSchedule: Codable, Equatable, Sendable {
    public var entries: [AmortizationEntry]
    public var monthlyPayment: Decimal
    public var totalInterest: Decimal
    public var totalPayment: Decimal
    public var payoffDate: Date?
    public var initialPrincipal: Decimal

    public init(
        entries: [AmortizationEntry],
        monthlyPayment: Decimal,
        totalInterest: Decimal,
        totalPayment: Decimal,
        payoffDate: Date?,
        initialPrincipal: Decimal
    ) {
        self.entries = entries
        self.monthlyPayment = monthlyPayment
        self.totalInterest = totalInterest
        self.totalPayment = totalPayment
        self.payoffDate = payoffDate
        self.initialPrincipal = initialPrincipal
    }

    public static let empty = AmortizationSchedule(
        entries: [],
        monthlyPayment: 0,
        totalInterest: 0,
        totalPayment: 0,
        payoffDate: nil,
        initialPrincipal: 0
    )

    public func remainingBalance(asOf date: Date) -> Decimal? {
        let elapsedEntries = entries.filter { $0.dueDate <= date }
        if let last = elapsedEntries.last {
            return last.remainingBalance
        }
        return entries.first.map { _ in initialPrincipal }
    }

    public func progressFraction(asOf date: Date) -> Double {
        guard initialPrincipal > 0 else {
            return 0
        }
        let remaining = remainingBalance(asOf: date) ?? initialPrincipal
        let paid = max(initialPrincipal - remaining, 0)
        let initialDouble = NSDecimalNumber(decimal: initialPrincipal).doubleValue
        let paidDouble = NSDecimalNumber(decimal: paid).doubleValue
        return min(max(paidDouble / initialDouble, 0), 1)
    }

    public func entriesAfter(_ date: Date) -> [AmortizationEntry] {
        entries.filter { $0.dueDate > date }
    }
}
