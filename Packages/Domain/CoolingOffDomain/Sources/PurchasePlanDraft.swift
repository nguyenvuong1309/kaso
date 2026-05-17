import Foundation

public enum PurchasePlanValidationError: String, Error, Codable, Equatable, Sendable {
    case titleRequired
    case amountMustBePositive
}

public struct PurchasePlanDraft: Codable, Equatable, Sendable {
    public var title: String
    public var amount: Decimal
    public var category: PurchasePlanCategory
    public var coolingPeriod: CoolingPeriod
    public var note: String?

    public init(
        title: String = "",
        amount: Decimal = 0,
        category: PurchasePlanCategory = .other,
        coolingPeriod: CoolingPeriod = .threeDays,
        note: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.category = category
        self.coolingPeriod = coolingPeriod
        self.note = note
    }

    public init(plan: PurchasePlan) {
        title = plan.title
        amount = plan.amount
        category = plan.category
        coolingPeriod = plan.coolingPeriod
        note = plan.note
    }

    public func validationErrors() -> [PurchasePlanValidationError] {
        var errors: [PurchasePlanValidationError] = []
        if trimmedTitle.isEmpty {
            errors.append(.titleRequired)
        }
        if amount <= 0 {
            errors.append(.amountMustBePositive)
        }
        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        now: Date = Date()
    ) throws -> PurchasePlan {
        if let firstError = validationErrors().first {
            throw firstError
        }
        let availableAt = now.addingTimeInterval(coolingPeriod.seconds)
        return PurchasePlan(
            id: id(),
            title: trimmedTitle,
            amount: amount,
            category: category,
            note: trimmedNote,
            coolingPeriod: coolingPeriod,
            status: .waiting,
            createdAt: now,
            availableAt: availableAt
        )
    }

    public func updating(existing: PurchasePlan, now: Date = Date()) throws -> PurchasePlan {
        if let firstError = validationErrors().first {
            throw firstError
        }
        let availableAt = existing.coolingPeriod == coolingPeriod
            ? existing.availableAt
            : existing.createdAt.addingTimeInterval(coolingPeriod.seconds)
        return PurchasePlan(
            id: existing.id,
            title: trimmedTitle,
            amount: amount,
            category: category,
            note: trimmedNote,
            coolingPeriod: coolingPeriod,
            status: existing.status,
            createdAt: existing.createdAt,
            availableAt: availableAt,
            decisionAt: existing.decisionAt
        )
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String? {
        guard let note else {
            return nil
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public extension PurchasePlanValidationError {
    var messageKey: String {
        switch self {
        case .titleRequired:
            "coolingOff.error.titleRequired"
        case .amountMustBePositive:
            "coolingOff.error.amountMustBePositive"
        }
    }
}
