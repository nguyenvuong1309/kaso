import Foundation

public enum LiabilityValidationError: String, Error, Codable, Equatable, Sendable {
    case nameRequired
    case principalCannotBeNegative
}

public struct LiabilityDraft: Codable, Equatable, Sendable {
    public var name: String
    public var type: LiabilityType
    public var principalRemaining: Decimal
    public var note: String?

    public init(
        name: String = "",
        type: LiabilityType = .personalLoan,
        principalRemaining: Decimal = 0,
        note: String? = nil
    ) {
        self.name = name
        self.type = type
        self.principalRemaining = principalRemaining
        self.note = note
    }

    public init(liability: Liability) {
        self.name = liability.name
        self.type = liability.type
        self.principalRemaining = liability.principalRemaining
        self.note = liability.note
    }

    public func validationErrors() -> [LiabilityValidationError] {
        var errors: [LiabilityValidationError] = []

        if trimmedName.isEmpty {
            errors.append(.nameRequired)
        }

        if principalRemaining < 0 {
            errors.append(.principalCannotBeNegative)
        }

        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        lastUpdatedAt: Date = Date()
    ) throws -> Liability {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Liability(
            id: id(),
            name: trimmedName,
            type: type,
            principalRemaining: principalRemaining,
            note: trimmedNote,
            lastUpdatedAt: lastUpdatedAt
        )
    }

    public func updating(
        existing: Liability,
        lastUpdatedAt: Date = Date()
    ) throws -> Liability {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Liability(
            id: existing.id,
            name: trimmedName,
            type: type,
            principalRemaining: principalRemaining,
            note: trimmedNote,
            isAutoTracked: existing.isAutoTracked,
            lastUpdatedAt: lastUpdatedAt
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
