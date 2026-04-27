import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("answers month status from current financial data")
func answersMonthStatusFromCurrentFinancialData() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let transactions = try [
        income(amount: 12_000_000, date: date(2026, 4, 1, calendar: calendar)),
        expense(amount: 4_000_000, category: .food, date: date(2026, 4, 12, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tháng này tôi còn bao nhiêu tiền?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .monthStatus)
    #expect(answer.risk == .positive)
    #expect(answer.amount(for: .balance) == 8_000_000)
    #expect(answer.amount(for: .projectedBalance) == 8_000_000)
}

@Test("detects affordability question and requested amount")
func detectsAffordabilityQuestionAndRequestedAmount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let transactions = try [
        income(amount: 5_000_000, date: date(2026, 4, 1, calendar: calendar)),
        expense(amount: 1_000_000, category: .transport, date: date(2026, 4, 10, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi còn đủ tiền mua vé 2 triệu không?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .affordability)
    #expect(answer.risk == .positive)
    #expect(answer.requestedAmount == 2_000_000)
    #expect(answer.amount(for: .projectedBalance) == 4_000_000)
}

@Test("suggests cuts from category spike")
func suggestsCutsFromCategorySpike() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let transactions = try [
        expense(amount: 3_000_000, category: .food, date: date(2026, 4, 20, calendar: calendar)),
        expense(amount: 1_000_000, category: .food, date: date(2026, 3, 20, calendar: calendar)),
        expense(amount: 1_000_000, category: .food, date: date(2026, 2, 20, calendar: calendar)),
        expense(amount: 1_000_000, category: .food, date: date(2026, 1, 20, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi nên cắt khoản nào để tiết kiệm thêm 1 triệu?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .savingsCut)
    #expect(answer.risk == .positive)
    #expect(answer.recommendedCategory == .food)
    #expect(answer.amount(for: .suggestedSaving) == 1_000_000)
}

@Test("unknown question falls back to data-aware summary")
func unknownQuestionFallsBackToDataAwareSummary() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, calendar: calendar)
    let answer = FinancialAssistantEngine.answer(
        question: "Hôm nay trời mưa không?",
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .unknown)
    #expect(answer.confidence < 0.5)
    #expect(answer.facts.isEmpty == false)
}

private func income(amount: Decimal, date: Date) -> Transaction {
    Transaction(
        amount: amount,
        kind: .income,
        category: .salary,
        occurredAt: date
    )
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
            day: day,
            hour: 12
        ).date
    )
}
