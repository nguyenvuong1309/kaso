import Foundation
import PersistenceKit
import Testing
import TransactionDomain

@Test("saves and fetches custom transaction categories encrypted")
func savesAndFetchesCustomTransactionCategoriesEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("custom-categories.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let categories = [
        TransactionCategory(
            id: "custom-coffee",
            nameKey: "Coffee",
            symbolName: "cup.and.saucer",
            colorName: "brown"
        ),
    ]
    let store = EncryptedTransactionCategoryStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 15, count: 32) }
    )

    try await store.saveCustomCategories(categories)

    let reloadedStore = EncryptedTransactionCategoryStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 15, count: 32) }
    )
    let loadedCategories = try await reloadedStore.fetchCustomCategories()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode(categories)

    #expect(loadedCategories == categories)
    #expect(rawData != plainData)
}
