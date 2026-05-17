import Foundation
import Testing
import TransactionDomain
@testable import QuickEntryIntent

@Test("LogExpenseIntent saves transaction with provided category and amount")
func logExpenseSavesTransaction() async throws {
    let store = TransactionRecorder()
    let repository = TransactionRepository(
        fetchAll: { await store.transactions },
        save: { transaction in await store.append(transaction) }
    )

    try await QuickEntryIntentEnvironment.$transactionRepositoryOverride.withValue(repository) {
        let intent = LogExpenseIntent(
            category: TransactionCategoryEntity(.food),
            amount: 45_000
        )
        _ = try await intent.perform()
    }

    let saved = await store.transactions
    #expect(saved.count == 1)
    #expect(saved.first?.amount == 45_000)
    #expect(saved.first?.kind == .expense)
    #expect(saved.first?.category.id == "food")
}

@Test("LogExpenseIntent rejects zero amount")
func logExpenseRejectsZero() async throws {
    let store = TransactionRecorder()
    let repository = TransactionRepository(
        fetchAll: { await store.transactions },
        save: { transaction in await store.append(transaction) }
    )

    await #expect(throws: TransactionValidationError.self) {
        try await QuickEntryIntentEnvironment.$transactionRepositoryOverride.withValue(repository) {
            let intent = LogExpenseIntent(
                category: TransactionCategoryEntity(.food),
                amount: 0
            )
            _ = try await intent.perform()
        }
    }
}

@Test("LogIncomeIntent saves income transaction")
func logIncomeSavesTransaction() async throws {
    let store = TransactionRecorder()
    let repository = TransactionRepository(
        fetchAll: { await store.transactions },
        save: { transaction in await store.append(transaction) }
    )

    try await QuickEntryIntentEnvironment.$transactionRepositoryOverride.withValue(repository) {
        let intent = LogIncomeIntent(
            category: IncomeCategoryEntity(.salary),
            amount: 20_000_000
        )
        _ = try await intent.perform()
    }

    let saved = await store.transactions
    #expect(saved.count == 1)
    #expect(saved.first?.kind == .income)
    #expect(saved.first?.category.id == "salary")
    #expect(saved.first?.amount == 20_000_000)
}

@Test("ExpenseCategoryQuery returns default expense categories")
func expenseQueryReturnsDefaults() async throws {
    let query = ExpenseCategoryQuery()
    let suggestions = try await query.suggestedEntities()
    let ids = Set(suggestions.map(\.id))

    #expect(ids.contains("food"))
    #expect(ids.contains("transport"))
    #expect(ids.contains("housing"))
}

@Test("IncomeCategoryQuery returns default income categories")
func incomeQueryReturnsDefaults() async throws {
    let query = IncomeCategoryQuery()
    let suggestions = try await query.suggestedEntities()
    let ids = Set(suggestions.map(\.id))

    #expect(ids.contains("salary"))
}

actor TransactionRecorder {
    private(set) var transactions: [Transaction] = []

    func append(_ transaction: Transaction) {
        transactions.append(transaction)
    }
}
