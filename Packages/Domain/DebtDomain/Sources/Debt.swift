import Foundation
import WealthDomain

public struct Debt: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var type: DebtType
    public var principal: Decimal
    public var annualInterestRatePercent: Decimal
    public var termMonths: Int
    public var startDate: Date
    public var paymentDay: Int
    public var monthlyPaymentOverride: Decimal?
    public var note: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: DebtType,
        principal: Decimal,
        annualInterestRatePercent: Decimal,
        termMonths: Int,
        startDate: Date,
        paymentDay: Int = 1,
        monthlyPaymentOverride: Decimal? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.principal = principal
        self.annualInterestRatePercent = annualInterestRatePercent
        self.termMonths = termMonths
        self.startDate = startDate
        self.paymentDay = paymentDay
        self.monthlyPaymentOverride = monthlyPaymentOverride
        self.note = note
        self.createdAt = createdAt
    }

    public var monthlyInterestRate: Decimal {
        annualInterestRatePercent / Decimal(100) / Decimal(12)
    }
}

public extension Debt {
    func toLiability(asOf date: Date = Date(), calendar: Calendar = .current) -> Liability {
        let schedule = (try? AmortizationCalculator.schedule(for: self, calendar: calendar)) ?? AmortizationSchedule.empty
        let remaining = schedule.remainingBalance(asOf: date) ?? principal
        return Liability(
            id: id,
            name: name,
            type: type.toLiabilityType(),
            principalRemaining: remaining,
            note: note,
            isAutoTracked: true,
            lastUpdatedAt: date
        )
    }
}

public extension DebtType {
    func toLiabilityType() -> LiabilityType {
        switch self {
        case .mortgage:
            .mortgage
        case .autoLoan:
            .autoLoan
        case .personalLoan:
            .personalLoan
        case .creditCard:
            .creditCard
        case .studentLoan:
            .studentLoan
        case .bnpl:
            .bnpl
        case .other:
            .other
        }
    }
}
