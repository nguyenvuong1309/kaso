import Foundation

public enum PhantomExpenseValidationError: String, Error, Codable, Equatable, Sendable {
    case titleRequired
    case amountMustBePositive
}

public struct PhantomExpenseDraft: Codable, Equatable, Sendable {
    public var title: String
    public var amount: Decimal
    public var category: PhantomExpenseCategory
    public var avoidedAt: Date
    public var note: String?

    public init(
        title: String = "",
        amount: Decimal = 0,
        category: PhantomExpenseCategory = .other,
        avoidedAt: Date = Date(),
        note: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.category = category
        self.avoidedAt = avoidedAt
        self.note = note
    }

    public init(expense: PhantomExpense) {
        title = expense.title
        amount = expense.amount
        category = expense.category
        avoidedAt = expense.avoidedAt
        note = expense.note
    }

    public func validationErrors() -> [PhantomExpenseValidationError] {
        var errors: [PhantomExpenseValidationError] = []
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
        createdAt: @autoclosure () -> Date = Date()
    ) throws -> PhantomExpense {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return PhantomExpense(
            id: id(),
            title: trimmedTitle,
            amount: amount,
            category: category,
            avoidedAt: avoidedAt,
            note: trimmedNote,
            createdAt: createdAt()
        )
    }

    public func updating(existing: PhantomExpense) throws -> PhantomExpense {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return PhantomExpense(
            id: existing.id,
            title: trimmedTitle,
            amount: amount,
            category: category,
            avoidedAt: avoidedAt,
            note: trimmedNote,
            createdAt: existing.createdAt
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
