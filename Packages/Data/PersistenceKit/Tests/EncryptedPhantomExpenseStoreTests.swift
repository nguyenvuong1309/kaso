import Foundation
import PersistenceKit
import PhantomExpenseDomain
import Testing

@Test("saves fetches and deletes phantom expenses encrypted")
func savesFetchesAndDeletesPhantomExpensesEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("phantom-expenses.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let expense = PhantomExpense(
        title: "Huỷ subscription",
        amount: 300_000,
        category: .subscription,
        avoidedAt: Date(timeIntervalSinceReferenceDate: 100),
        createdAt: Date(timeIntervalSinceReferenceDate: 50)
    )
    let store = EncryptedPhantomExpenseStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 61, count: 32) }
    )

    try await store.save(expense)

    let loadedExpenses = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([expense])

    #expect(loadedExpenses == [expense])
    #expect(rawData != plainData)

    try await store.delete(expense.id)
    #expect(try await store.fetchAll() == [])
}
