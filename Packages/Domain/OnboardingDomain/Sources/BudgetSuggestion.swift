import Foundation
import TransactionDomain

public struct BudgetSuggestion: Identifiable, Codable, Equatable, Sendable {
    public var category: TransactionCategory
    public var monthlyLimit: Decimal

    public init(
        category: TransactionCategory,
        monthlyLimit: Decimal
    ) {
        self.category = category
        self.monthlyLimit = monthlyLimit
    }

    public var id: String {
        category.id
    }
}
