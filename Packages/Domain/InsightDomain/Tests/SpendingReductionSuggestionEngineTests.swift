import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("suggests reducing category spike against historical baseline")
func suggestsReducingCategorySpikeAgainstHistoricalBaseline() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        expense(amount: 1_000_000, category: .food, date: date(2026, 1, 10, calendar: calendar)),
        expense(amount: 1_000_000, category: .food, date: date(2026, 2, 10, calendar: calendar)),
        expense(amount: 1_000_000, category: .food, date: date(2026, 3, 10, calendar: calendar)),
        expense(amount: 1_600_000, category: .food, date: date(2026, 4, 20, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try date(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    let suggestion = try #require(suggestions.first)
    #expect(suggestions.count == 1)
    #expect(suggestion.kind == .categorySpike)
    #expect(suggestion.category == .food)
    #expect(suggestion.currentMonthlyAmount == 1_600_000)
    #expect(suggestion.baselineMonthlyAmount == 1_000_000)
    #expect(suggestion.suggestedMonthlySaving == 300_000)
    #expect(suggestion.projectedMonthlyAmount == 1_300_000)
}

@Test("suggests trimming dominant category without baseline")
func suggestsTrimmingDominantCategoryWithoutBaseline() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        expense(amount: 2_000_000, category: .shopping, date: date(2026, 4, 12, calendar: calendar)),
        expense(amount: 300_000, category: .transport, date: date(2026, 4, 13, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try date(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    let suggestion = try #require(suggestions.first)
    #expect(suggestion.kind == .dominantCategory)
    #expect(suggestion.category == .shopping)
    #expect(suggestion.suggestedMonthlySaving == 200_000)
}

@Test("ignores income and small changes")
func ignoresIncomeAndSmallChanges() throws {
    let calendar = Calendar(identifier: .gregorian)
    let transactions = try [
        Transaction(
            amount: 30_000_000,
            kind: .income,
            category: .salary,
            occurredAt: date(2026, 4, 1, calendar: calendar)
        ),
        expense(amount: 1_000_000, category: .food, date: date(2026, 3, 10, calendar: calendar)),
        expense(amount: 1_050_000, category: .food, date: date(2026, 4, 10, calendar: calendar)),
    ]

    let suggestions = SpendingReductionSuggestionEngine.suggestions(
        transactions: transactions,
        referenceDate: try date(2026, 4, 26, calendar: calendar),
        calendar: calendar
    )

    #expect(suggestions.isEmpty)
}

private func expense(
    amount: Decimal,
    category: TransactionCategory,
    date: Date
) -> Transaction {
    Transaction(
        amount: amount,
        kind: .expense,
        category: category,
        occurredAt: date
    )
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        ).date
    )
}
