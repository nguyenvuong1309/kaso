import BudgetDomain
import Foundation
import PersistenceKit
import Testing
import TransactionDomain

@Test("saves and fetches budgets encrypted")
func savesAndFetchesBudgetsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("budgets.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let budgets = [
        Budget(category: .food, monthlyLimit: 3_000_000),
        Budget(category: .transport, monthlyLimit: 1_000_000),
    ]
    let store = EncryptedBudgetStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 13, count: 32) }
    )

    try await store.saveAll(budgets)

    let reloadedStore = EncryptedBudgetStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 13, count: 32) }
    )
    let loadedBudgets = try await reloadedStore.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode(budgets)

    #expect(loadedBudgets == budgets)
    #expect(rawData != plainData)
}
