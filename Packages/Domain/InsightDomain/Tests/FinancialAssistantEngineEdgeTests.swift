import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("top-category question surfaces the largest expense category")
func assistantTopCategoryQuestion() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantExpense(amount: 3_000_000, category: .food, date: assistantDate(2026, 4, 10, calendar: calendar)),
        assistantExpense(amount: 1_000_000, category: .transport, date: assistantDate(2026, 4, 12, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Danh mục nào tôi chi nhiều nhất?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .topCategory)
    #expect(answer.risk == .neutral)
    #expect(answer.recommendedCategory == .food)
    #expect(answer.amount(for: .topCategoryExpense) == 3_000_000)
    #expect(answer.amount(for: .expense) == 4_000_000)
}

@Test("top-category question with no expenses returns only the expense fact")
func assistantTopCategoryWithoutExpenses() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi chi nhiều nhất ở đâu?",
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .topCategory)
    #expect(answer.recommendedCategory == nil)
    #expect(answer.amount(for: .topCategoryExpense) == nil)
    #expect(answer.amount(for: .expense) == 0)
    #expect(answer.confidence == 0.75)
}

@Test("affordability without a recognizable amount stays neutral")
func assistantAffordabilityWithoutAmount() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantIncome(amount: 5_000_000, date: assistantDate(2026, 4, 1, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi có đủ tiền đi du lịch không?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .affordability)
    #expect(answer.risk == .neutral)
    #expect(answer.requestedAmount == nil)
    #expect(answer.confidence == 0.65)
}

@Test("affordability is critical when neither balance nor forecast can cover the cost")
func assistantAffordabilityCritical() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantIncome(amount: 3_000_000, date: assistantDate(2026, 4, 1, calendar: calendar)),
        assistantExpense(amount: 1_000_000, category: .food, date: assistantDate(2026, 4, 10, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi có đủ tiền mua xe 50 trieu không?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .affordability)
    #expect(answer.requestedAmount == 50_000_000)
    #expect(answer.risk == .critical)
}

@Test("affordability is a warning when only the current balance covers it")
func assistantAffordabilityWarning() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    // Heavy historical pace pushes the projected balance below the requested amount,
    // while the current balance still covers it.
    let transactions = try [
        assistantIncome(amount: 20_000_000, date: assistantDate(2026, 4, 1, calendar: calendar)),
        assistantExpense(amount: 2_000_000, category: .food, date: assistantDate(2026, 4, 2, calendar: calendar)),
        assistantExpense(amount: 16_000_000, category: .housing, date: assistantDate(2026, 3, 10, calendar: calendar)),
        assistantExpense(amount: 16_000_000, category: .housing, date: assistantDate(2026, 2, 10, calendar: calendar)),
        assistantExpense(amount: 16_000_000, category: .housing, date: assistantDate(2026, 1, 10, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi còn đủ tiền mua vé 15 trieu không?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .affordability)
    #expect(answer.requestedAmount == 15_000_000)
    #expect(answer.risk == .warning)
}

@Test("savings-cut is a warning when the suggested saving misses the target")
func assistantSavingsCutWarning() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantExpense(amount: 3_000_000, category: .food, date: assistantDate(2026, 4, 20, calendar: calendar)),
        assistantExpense(amount: 1_000_000, category: .food, date: assistantDate(2026, 3, 20, calendar: calendar)),
        assistantExpense(amount: 1_000_000, category: .food, date: assistantDate(2026, 2, 20, calendar: calendar)),
        assistantExpense(amount: 1_000_000, category: .food, date: assistantDate(2026, 1, 20, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Tôi nên giảm khoản nào để tiết kiệm thêm 5 trieu?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .savingsCut)
    #expect(answer.requestedAmount == 5_000_000)
    // suggested saving (1,000,000) < target (5,000,000)
    #expect(answer.risk == .warning)
}

@Test("savings-cut falls back to a share of the top category when no spike exists")
func assistantSavingsCutFallback() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantExpense(amount: 500_000, category: .food, date: assistantDate(2026, 4, 10, calendar: calendar)),
        assistantExpense(amount: 200_000, category: .transport, date: assistantDate(2026, 4, 12, calendar: calendar)),
    ]

    let answer = FinancialAssistantEngine.answer(
        question: "Làm sao để bớt chi tiêu?",
        transactions: transactions,
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .savingsCut)
    #expect(answer.requestedAmount == nil)
    #expect(answer.recommendedCategory == .food)
    // fallback = 10% of top category (500,000) rounded to thousands = 50,000
    #expect(answer.amount(for: .suggestedSaving) == 50_000)
    #expect(answer.confidence == 0.65)
    // suggested saving > 0 and no target -> positive
    #expect(answer.risk == .positive)
}

@Test("parses amounts in million, thousand, k and bare large-number forms")
func assistantParsesAmountVariants() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)
    let transactions = try [
        assistantIncome(amount: 100_000_000, date: assistantDate(2026, 4, 1, calendar: calendar)),
    ]

    func requested(_ question: String) -> Decimal? {
        FinancialAssistantEngine.answer(
            question: question,
            transactions: transactions,
            referenceDate: referenceDate,
            calendar: calendar
        ).requestedAmount
    }

    #expect(requested("Tôi có đủ tiền mua 2 trieu không?") == 2_000_000)
    #expect(requested("Tôi có đủ tiền mua 500 nghin không?") == 500_000)
    #expect(requested("Tôi có đủ tiền mua 200k không?") == 200_000)
    #expect(requested("Tôi có đủ tiền mua 50000 không?") == 50_000)
    // numbers under 10,000 with no unit are not amounts
    #expect(requested("Tôi có đủ tiền mua 5 không?") == nil)
}

@Test("month-status without data reports zeroed facts at safe risk")
func assistantMonthStatusEmpty() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try assistantDate(2026, 4, 30, calendar: calendar)

    let answer = FinancialAssistantEngine.answer(
        question: "Số dư của tôi thế nào?",
        transactions: [],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(answer.intent == .monthStatus)
    #expect(answer.amount(for: .income) == 0)
    #expect(answer.amount(for: .expense) == 0)
    #expect(answer.amount(for: .balance) == 0)
    #expect(answer.amount(for: .projectedBalance) == 0)
    #expect(answer.risk == .positive)
    #expect(answer.confidence == 0.9)
}

private func assistantIncome(amount: Decimal, date: Date) -> Transaction {
    Transaction(amount: amount, kind: .income, category: .salary, occurredAt: date)
}

private func assistantExpense(
    amount: Decimal,
    category: TransactionCategory,
    date: Date
) -> Transaction {
    Transaction(amount: amount, kind: .expense, category: category, occurredAt: date)
}

private func assistantDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: 12).date
    )
}
