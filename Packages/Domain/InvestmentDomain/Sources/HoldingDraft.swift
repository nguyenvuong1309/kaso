import Foundation

public enum HoldingValidationError: String, Error, Codable, Equatable, Sendable {
    case symbolRequired
    case nameRequired
    case lotsRequired
    case lotQuantityMustBePositive
    case lotCostBasisCannotBeNegative
}

public struct LotDraft: Codable, Equatable, Sendable {
    public var id: UUID
    public var quantity: Decimal
    public var costBasisPerUnit: Decimal
    public var purchasedAt: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        quantity: Decimal = 0,
        costBasisPerUnit: Decimal = 0,
        purchasedAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.quantity = quantity
        self.costBasisPerUnit = costBasisPerUnit
        self.purchasedAt = purchasedAt
        self.note = note
    }

    public init(lot: InvestmentLot) {
        self.id = lot.id
        self.quantity = lot.quantity
        self.costBasisPerUnit = lot.costBasisPerUnit
        self.purchasedAt = lot.purchasedAt
        self.note = lot.note
    }

    public func toLot() -> InvestmentLot {
        InvestmentLot(
            id: id,
            quantity: quantity,
            costBasisPerUnit: costBasisPerUnit,
            purchasedAt: purchasedAt,
            note: trimmedNote
        )
    }

    private var trimmedNote: String? {
        guard let note else {
            return nil
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct HoldingDraft: Codable, Equatable, Sendable {
    public var symbol: String
    public var name: String
    public var assetClass: AssetClass
    public var currency: String
    public var lots: [LotDraft]
    public var note: String?

    public init(
        symbol: String = "",
        name: String = "",
        assetClass: AssetClass = .stock,
        currency: String = "VND",
        lots: [LotDraft] = [LotDraft()],
        note: String? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.assetClass = assetClass
        self.currency = currency
        self.lots = lots
        self.note = note
    }

    public init(holding: Holding) {
        self.symbol = holding.symbol
        self.name = holding.name
        self.assetClass = holding.assetClass
        self.currency = holding.currency
        self.lots = holding.lots.map(LotDraft.init(lot:))
        self.note = holding.note
    }

    public func validationErrors() -> [HoldingValidationError] {
        var errors: [HoldingValidationError] = []

        if trimmedSymbol.isEmpty {
            errors.append(.symbolRequired)
        }
        if trimmedName.isEmpty {
            errors.append(.nameRequired)
        }
        if lots.isEmpty {
            errors.append(.lotsRequired)
        }
        if lots.contains(where: { $0.quantity <= 0 }) {
            errors.append(.lotQuantityMustBePositive)
        }
        if lots.contains(where: { $0.costBasisPerUnit < 0 }) {
            errors.append(.lotCostBasisCannotBeNegative)
        }

        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        createdAt: Date = Date()
    ) throws -> Holding {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Holding(
            id: id(),
            symbol: trimmedSymbol,
            name: trimmedName,
            assetClass: assetClass,
            currency: trimmedCurrency,
            lots: lots.map { $0.toLot() },
            note: trimmedNote,
            createdAt: createdAt
        )
    }

    public func updating(existing: Holding) throws -> Holding {
        if let firstError = validationErrors().first {
            throw firstError
        }

        return Holding(
            id: existing.id,
            symbol: trimmedSymbol,
            name: trimmedName,
            assetClass: assetClass,
            currency: trimmedCurrency,
            lots: lots.map { $0.toLot() },
            note: trimmedNote,
            createdAt: existing.createdAt
        )
    }

    private var trimmedSymbol: String {
        symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCurrency: String {
        let value = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return value.isEmpty ? "VND" : value
    }

    private var trimmedNote: String? {
        guard let note else {
            return nil
        }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
