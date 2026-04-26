import Foundation
import TransactionDomain

public enum SpendingReductionSuggestionKind: String, Codable, Equatable, Sendable {
    case categorySpike
    case dominantCategory

    public var titleKey: String {
        "insight.reduction.\(rawValue).title"
    }

    public var descriptionKey: String {
        "insight.reduction.\(rawValue).description"
    }
}

public struct SpendingReductionSuggestion: Identifiable, Codable, Equatable, Sendable {
    public var id: String {
        "reduction-\(kind.rawValue)-\(category.id)"
    }

    public var kind: SpendingReductionSuggestionKind
    public var category: TransactionCategory
    public var currentMonthlyAmount: Decimal
    public var baselineMonthlyAmount: Decimal
    public var suggestedMonthlySaving: Decimal
    public var projectedMonthlyAmount: Decimal

    public init(
        kind: SpendingReductionSuggestionKind,
        category: TransactionCategory,
        currentMonthlyAmount: Decimal,
        baselineMonthlyAmount: Decimal,
        suggestedMonthlySaving: Decimal,
        projectedMonthlyAmount: Decimal
    ) {
        self.kind = kind
        self.category = category
        self.currentMonthlyAmount = currentMonthlyAmount
        self.baselineMonthlyAmount = baselineMonthlyAmount
        self.suggestedMonthlySaving = suggestedMonthlySaving
        self.projectedMonthlyAmount = projectedMonthlyAmount
    }
}
