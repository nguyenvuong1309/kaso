import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("suggestion kind exposes localization keys")
func suggestionKindKeys() {
    #expect(SpendingReductionSuggestionKind.categorySpike.titleKey == "insight.reduction.categorySpike.title")
    #expect(SpendingReductionSuggestionKind.categorySpike.descriptionKey == "insight.reduction.categorySpike.description")
    #expect(SpendingReductionSuggestionKind.dominantCategory.titleKey == "insight.reduction.dominantCategory.title")
}

@Test("suggestion id combines kind and category id")
func suggestionIdCombinesKindAndCategory() {
    let suggestion = makeSuggestion(kind: .categorySpike, category: .food)
    #expect(suggestion.id == "reduction-categorySpike-food")

    let dominant = makeSuggestion(kind: .dominantCategory, category: .shopping)
    #expect(dominant.id == "reduction-dominantCategory-shopping")
}

@Test("suggestion round-trips through Codable")
func suggestionRoundTripsThroughCodable() throws {
    let suggestion = SpendingReductionSuggestion(
        kind: .categorySpike,
        category: .transport,
        currentMonthlyAmount: 1_600_000,
        baselineMonthlyAmount: 1_000_000,
        suggestedMonthlySaving: 300_000,
        projectedMonthlyAmount: 1_300_000
    )
    let data = try JSONEncoder().encode(suggestion)
    let decoded = try JSONDecoder().decode(SpendingReductionSuggestion.self, from: data)
    #expect(decoded == suggestion)
    #expect(decoded.id == suggestion.id)
}

private func makeSuggestion(
    kind: SpendingReductionSuggestionKind,
    category: TransactionCategory
) -> SpendingReductionSuggestion {
    SpendingReductionSuggestion(
        kind: kind,
        category: category,
        currentMonthlyAmount: 1_000_000,
        baselineMonthlyAmount: 0,
        suggestedMonthlySaving: 100_000,
        projectedMonthlyAmount: 900_000
    )
}
