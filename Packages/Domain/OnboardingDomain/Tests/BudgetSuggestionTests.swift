import Foundation
import Testing
import TransactionDomain
@testable import OnboardingDomain

@Test("derives its identity from the category id")
func budgetSuggestionIdMatchesCategory() {
    let suggestion = BudgetSuggestion(category: .food, monthlyLimit: 1_000_000)
    #expect(suggestion.id == TransactionCategory.food.id)
    #expect(suggestion.id == "food")
}

@Test("stores the category and monthly limit it was created with")
func budgetSuggestionStoresValues() {
    let suggestion = BudgetSuggestion(category: .housing, monthlyLimit: 7_000_000)
    #expect(suggestion.category == .housing)
    #expect(suggestion.monthlyLimit == Decimal(7_000_000))
}

@Test("equality considers both category and monthly limit")
func budgetSuggestionEquality() {
    let base = BudgetSuggestion(category: .transport, monthlyLimit: 2_000_000)
    #expect(base == BudgetSuggestion(category: .transport, monthlyLimit: 2_000_000))
    #expect(base != BudgetSuggestion(category: .transport, monthlyLimit: 2_500_000))
    #expect(base != BudgetSuggestion(category: .food, monthlyLimit: 2_000_000))
}

@Test("round-trips through Codable preserving category and limit")
func budgetSuggestionCodableRoundTrip() throws {
    let suggestion = BudgetSuggestion(category: .education, monthlyLimit: 1_234_567.89)
    let data = try JSONEncoder().encode(suggestion)
    let decoded = try JSONDecoder().decode(BudgetSuggestion.self, from: data)
    #expect(decoded == suggestion)
}

@Test("supports a zero monthly limit")
func budgetSuggestionZeroLimit() {
    let suggestion = BudgetSuggestion(category: .other, monthlyLimit: 0)
    #expect(suggestion.monthlyLimit == Decimal(0))
    #expect(suggestion.id == "other")
}
