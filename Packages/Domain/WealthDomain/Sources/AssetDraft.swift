import Foundation

public enum AssetValidationError: String, Error, Codable, Equatable, Sendable {
    case nameRequired
    case currentValueCannotBeNegative
}

public struct AssetDraft: Codable, Equatable, Sendable {
    public var name: String
    public var type: AssetType
    public var currentValue: Decimal
    public var acquiredAt: Date?
    public var note: String?

    public init(
        name: String = "",
        type: AssetType = .bankSavings,
        currentValue: Decimal = 0,
        acquiredAt: Date? = nil,
        note: String? = nil
    ) {
        self.name = name
        self.type = type
        self.currentValue = currentValue
        self.acquiredAt = acquiredAt
        self.note = note
    }

    public init(asset: Asset) {
        self.name = asset.name
        self.type = asset.type
        self.currentValue = asset.currentValue
        self.acquiredAt = asset.acquiredAt
        self.note = asset.note
    }

    public func validationErrors() -> [AssetValidationError] {
        var errors: [AssetValidationError] = []

        if trimmedName.isEmpty {
            errors.append(.nameRequired)
        }

        if currentValue < 0 {
            errors.append(.currentValueCannotBeNegative)
        }

        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        lastUpdatedAt: Date = Date()
    ) throws -> Asset {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Asset(
            id: id(),
            name: trimmedName,
            type: type,
            currentValue: currentValue,
            acquiredAt: acquiredAt,
            note: trimmedNote,
            lastUpdatedAt: lastUpdatedAt
        )
    }

    public func updating(
        existing: Asset,
        lastUpdatedAt: Date = Date()
    ) throws -> Asset {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Asset(
            id: existing.id,
            name: trimmedName,
            type: type,
            currentValue: currentValue,
            acquiredAt: acquiredAt,
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
