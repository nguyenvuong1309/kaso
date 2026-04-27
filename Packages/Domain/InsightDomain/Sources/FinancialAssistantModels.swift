import Foundation
import TransactionDomain

public enum FinancialAssistantIntent: String, Equatable, Sendable {
    case monthStatus
    case affordability
    case savingsCut
    case topCategory
    case unknown

    public var titleKey: String {
        "assistant.intent.\(rawValue).title"
    }

    public var summaryKey: String {
        "assistant.answer.\(rawValue).summary"
    }
}

public enum FinancialAssistantRisk: String, Equatable, Sendable {
    case positive
    case neutral
    case warning
    case critical

    public var titleKey: String {
        "assistant.risk.\(rawValue)"
    }
}

public enum FinancialAssistantFactKind: String, Equatable, Sendable {
    case income
    case expense
    case balance
    case projectedBalance
    case requestedAmount
    case suggestedSaving
    case topCategoryExpense

    public var titleKey: String {
        "assistant.fact.\(rawValue)"
    }
}

public struct FinancialAssistantFact: Identifiable, Equatable, Sendable {
    public let id: String
    public var kind: FinancialAssistantFactKind
    public var amount: Decimal
    public var category: TransactionCategory?

    public init(
        kind: FinancialAssistantFactKind,
        amount: Decimal,
        category: TransactionCategory? = nil
    ) {
        id = Self.identifier(kind: kind, category: category)
        self.kind = kind
        self.amount = amount
        self.category = category
    }

    private static func identifier(
        kind: FinancialAssistantFactKind,
        category: TransactionCategory?
    ) -> String {
        if let category {
            return "\(kind.rawValue)-\(category.id)"
        }

        return kind.rawValue
    }
}

public struct FinancialAssistantAnswer: Equatable, Sendable {
    public var intent: FinancialAssistantIntent
    public var risk: FinancialAssistantRisk
    public var confidence: Double
    public var facts: [FinancialAssistantFact]
    public var requestedAmount: Decimal?
    public var recommendedCategory: TransactionCategory?

    public init(
        intent: FinancialAssistantIntent,
        risk: FinancialAssistantRisk,
        confidence: Double,
        facts: [FinancialAssistantFact],
        requestedAmount: Decimal? = nil,
        recommendedCategory: TransactionCategory? = nil
    ) {
        self.intent = intent
        self.risk = risk
        self.confidence = confidence
        self.facts = facts
        self.requestedAmount = requestedAmount
        self.recommendedCategory = recommendedCategory
    }

    public func amount(for kind: FinancialAssistantFactKind) -> Decimal? {
        facts.first { $0.kind == kind }?.amount
    }
}
