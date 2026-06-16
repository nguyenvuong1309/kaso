import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("no current-month spending yields no suggestions")
func reductionEngineEmptyWhenNoSpending() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        // only historical and income data; nothing in the reference month
        reductionExpense(amount: 2_000_000, category: .food, date: reductionDate(2026, 3, 10, calendar: calendar)),
        Transaction(amount: 10_000_000, kind: .income, category: .salary, occurredAt: reductionDate(2026, 4, 1, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try reductionDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(suggestions.isEmpty)
}

@Test("a category below the dominant share and amount floor is not suggested")
func reductionEngineSkipsSmallDominantCategory() throws {
    let calendar = Calendar(identifier: .gregorian)
    // Two equal categories: neither reaches the 35% dominant share with a 1,000,000 floor.
    let transactions = try [
        reductionExpense(amount: 400_000, category: .food, date: reductionDate(2026, 4, 10, calendar: calendar)),
        reductionExpense(amount: 400_000, category: .transport, date: reductionDate(2026, 4, 11, calendar: calendar)),
        reductionExpense(amount: 400_000, category: .shopping, date: reductionDate(2026, 4, 12, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try reductionDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(suggestions.isEmpty)
}

@Test("a spike below the 1.2x ratio threshold is not suggested")
func reductionEngineSkipsSmallSpike() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 1, 10, calendar: calendar)),
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 2, 10, calendar: calendar)),
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 3, 10, calendar: calendar)),
        // current 1,100,000 is only 1.1x baseline -> below 1.2x ratio
        reductionExpense(amount: 1_100_000, category: .food, date: reductionDate(2026, 4, 10, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try reductionDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(suggestions.isEmpty)
}

@Test("suggestions are ordered by descending suggested saving then category id")
func reductionEngineSortsBySaving() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        // food spike: baseline 1,000,000 -> current 3,000,000 (saving 1,000,000)
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 1, 10, calendar: calendar)),
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 2, 10, calendar: calendar)),
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 3, 10, calendar: calendar)),
        reductionExpense(amount: 3_000_000, category: .food, date: reductionDate(2026, 4, 10, calendar: calendar)),
        // shopping spike: baseline 2,000,000 -> current 4,000,000 (saving 1,000,000)
        reductionExpense(amount: 2_000_000, category: .shopping, date: reductionDate(2026, 1, 12, calendar: calendar)),
        reductionExpense(amount: 2_000_000, category: .shopping, date: reductionDate(2026, 2, 12, calendar: calendar)),
        reductionExpense(amount: 2_000_000, category: .shopping, date: reductionDate(2026, 3, 12, calendar: calendar)),
        reductionExpense(amount: 4_000_000, category: .shopping, date: reductionDate(2026, 4, 12, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try reductionDate(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(suggestions.count == 2)
    // equal savings -> tie broken by category id ("food" < "shopping")
    #expect(suggestions.map { $0.category.id } == ["food", "shopping"])
    #expect(suggestions.allSatisfy { $0.kind == .categorySpike })
}

@Test("custom lookback window changes the spike baseline")
func reductionEngineRespectsLookback() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        reductionExpense(amount: 1_000_000, category: .food, date: reductionDate(2026, 3, 10, calendar: calendar)),
        reductionExpense(amount: 2_000_000, category: .food, date: reductionDate(2026, 4, 10, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try reductionDate(2026, 4, 26, calendar: calendar),
        lookbackMonthCount: 1,
        calendar: calendar
    )

    let suggestion = try #require(suggestions.first)
    #expect(suggestion.kind == .categorySpike)
    #expect(suggestion.baselineMonthlyAmount == 1_000_000)
    // excess 1,000,000 * 50% reduction share = 500,000
    #expect(suggestion.suggestedMonthlySaving == 500_000)
}

private func reductionExpense(
    amount: Decimal,
    category: TransactionCategory,
    date: Date
) -> Transaction {
    Transaction(amount: amount, kind: .expense, category: category, occurredAt: date)
}

private func reductionDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
