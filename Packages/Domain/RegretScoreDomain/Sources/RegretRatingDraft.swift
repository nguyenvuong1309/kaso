import Foundation

public enum RegretRatingValidationError: String, Error, Codable, Equatable, Sendable {
    case titleRequired
    case amountMustBePositive
}

public struct RegretRatingDraft: Codable, Equatable, Sendable {
    public var purchaseTitle: String
    public var category: String
    public var amount: Decimal
    public var score: RegretScore
    public var note: String?
    public var purchasedAt: Date

    public init(
        purchaseTitle: String = "",
        category: String = "other",
        amount: Decimal = 0,
        score: RegretScore = .neutral,
        note: String? = nil,
        purchasedAt: Date = Date()
    ) {
        self.purchaseTitle = purchaseTitle
        self.category = category
        self.amount = amount
        self.score = score
        self.note = note
        self.purchasedAt = purchasedAt
    }

    public init(rating: RegretRating) {
        purchaseTitle = rating.purchaseTitle
        category = rating.category
        amount = rating.amount
        score = rating.score
        note = rating.note
        purchasedAt = rating.purchasedAt
    }

    public func validationErrors() -> [RegretRatingValidationError] {
        var errors: [RegretRatingValidationError] = []
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
    ) throws -> RegretRating {
        if let firstError = validationErrors().first {
            throw firstError
        }
        return RegretRating(
            id: id(),
            purchaseTitle: trimmedTitle,
            category: category.isEmpty ? "other" : category,
            amount: amount,
            score: score,
            note: trimmedNote,
            purchasedAt: purchasedAt,
            ratedAt: now
        )
    }

    public func updating(existing: RegretRating, now: Date = Date()) throws -> RegretRating {
        if let firstError = validationErrors().first {
            throw firstError
        }
        return RegretRating(
            id: existing.id,
            purchaseTitle: trimmedTitle,
            category: category.isEmpty ? "other" : category,
            amount: amount,
            score: score,
            note: trimmedNote,
            purchasedAt: purchasedAt,
            ratedAt: now
        )
    }

    private var trimmedTitle: String {
        purchaseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNote: String? {
        guard let note else {
            return nil
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public extension RegretRatingValidationError {
    var messageKey: String {
        switch self {
        case .titleRequired:
            "regret.error.titleRequired"
        case .amountMustBePositive:
            "regret.error.amountMustBePositive"
        }
    }
}
