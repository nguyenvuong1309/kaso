import Foundation

public enum DebtValidationError: String, Error, Codable, Equatable, Sendable {
    case nameRequired
    case principalMustBePositive
    case annualInterestRateCannotBeNegative
    case termMonthsMustBePositive
    case termMonthsTooLong
    case paymentDayOutOfRange
}

public struct DebtDraft: Codable, Equatable, Sendable {
    public static let maxTermMonths = 600

    public var name: String
    public var type: DebtType
    public var principal: Decimal
    public var annualInterestRatePercent: Decimal
    public var termMonths: Int
    public var startDate: Date
    public var paymentDay: Int
    public var monthlyPaymentOverride: Decimal?
    public var note: String?

    public init(
        name: String = "",
        type: DebtType = .personalLoan,
        principal: Decimal = 0,
        annualInterestRatePercent: Decimal = 0,
        termMonths: Int = 12,
        startDate: Date = Date(),
        paymentDay: Int = 1,
        monthlyPaymentOverride: Decimal? = nil,
        note: String? = nil
    ) {
        self.name = name
        self.type = type
        self.principal = principal
        self.annualInterestRatePercent = annualInterestRatePercent
        self.termMonths = termMonths
        self.startDate = startDate
        self.paymentDay = paymentDay
        self.monthlyPaymentOverride = monthlyPaymentOverride
        self.note = note
    }

    public init(debt: Debt) {
        self.name = debt.name
        self.type = debt.type
        self.principal = debt.principal
        self.annualInterestRatePercent = debt.annualInterestRatePercent
        self.termMonths = debt.termMonths
        self.startDate = debt.startDate
        self.paymentDay = debt.paymentDay
        self.monthlyPaymentOverride = debt.monthlyPaymentOverride
        self.note = debt.note
    }

    public func validationErrors() -> [DebtValidationError] {
        var errors: [DebtValidationError] = []

        if trimmedName.isEmpty {
            errors.append(.nameRequired)
        }

        if principal <= 0 {
            errors.append(.principalMustBePositive)
        }

        if annualInterestRatePercent < 0 {
            errors.append(.annualInterestRateCannotBeNegative)
        }

        if termMonths <= 0 {
            errors.append(.termMonthsMustBePositive)
        } else if termMonths > Self.maxTermMonths {
            errors.append(.termMonthsTooLong)
        }

        if !(1 ... 31).contains(paymentDay) {
            errors.append(.paymentDayOutOfRange)
        }

        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> Debt {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Debt(
            id: id(),
            name: trimmedName,
            type: type,
            principal: principal,
            annualInterestRatePercent: annualInterestRatePercent,
            termMonths: termMonths,
            startDate: startDate,
            paymentDay: paymentDay,
            monthlyPaymentOverride: monthlyPaymentOverride,
            note: trimmedNote,
            createdAt: createdAt
        )
    }

    public func updating(existing: Debt) throws -> Debt {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Debt(
            id: existing.id,
            name: trimmedName,
            type: type,
            principal: principal,
            annualInterestRatePercent: annualInterestRatePercent,
            termMonths: termMonths,
            startDate: startDate,
            paymentDay: paymentDay,
            monthlyPaymentOverride: monthlyPaymentOverride,
            note: trimmedNote,
            createdAt: existing.createdAt
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String? {
        guard let note else {
            return nil
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
