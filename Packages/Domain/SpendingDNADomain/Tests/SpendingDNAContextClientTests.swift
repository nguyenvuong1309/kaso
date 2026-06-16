import Foundation
import Testing
@testable import SpendingDNADomain

struct SpendingDNAContextClientTests {
    @Test("custom client returns the injected transactions")
    func customClientLoads() async throws {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        let expected = [
            SpendingDNATransactionInput(amount: 100, categoryID: "food", isExpense: true, occurredAt: date),
            SpendingDNATransactionInput(amount: 200, categoryID: "salary", isExpense: false, occurredAt: date),
        ]
        let client = SpendingDNAContextClient(loadTransactions: { expected })
        let loaded = try await client.loadTransactions()
        #expect(loaded == expected)
    }

    @Test("custom client can propagate a thrown error")
    func customClientThrows() async {
        struct LoadError: Error {}
        let client = SpendingDNAContextClient(loadTransactions: { throw LoadError() })
        await #expect(throws: LoadError.self) {
            _ = try await client.loadTransactions()
        }
    }

    @Test("empty client loads no transactions")
    func emptyClient() async throws {
        let loaded = try await SpendingDNAContextClient.empty.loadTransactions()
        #expect(loaded.isEmpty)
    }

    @Test("preview client produces sixty sample transactions")
    func previewCount() async throws {
        let loaded = try await SpendingDNAContextClient.preview.loadTransactions()
        #expect(loaded.count == 60)
    }

    @Test("preview client marks every sixth offset as income labelled salary")
    func previewIncomeLabelling() async throws {
        let loaded = try await SpendingDNAContextClient.preview.loadTransactions()
        let incomeEntries = loaded.filter { !$0.isExpense }
        #expect(!incomeEntries.isEmpty)
        #expect(incomeEntries.allSatisfy { $0.categoryID == "salary" })
    }

    @Test("preview expense entries use the rotating known categories")
    func previewExpenseCategories() async throws {
        let loaded = try await SpendingDNAContextClient.preview.loadTransactions()
        let expenseCategories = Set(loaded.filter(\.isExpense).map(\.categoryID))
        #expect(expenseCategories.isSubset(of: ["food", "transport", "shopping", "entertainment"]))
    }

    @Test("preview amounts stay within the generated range")
    func previewAmountRange() async throws {
        let loaded = try await SpendingDNAContextClient.preview.loadTransactions()
        #expect(loaded.allSatisfy { $0.amount >= 60_000 && $0.amount <= 60_000 + 6 * 40_000 })
    }
}
