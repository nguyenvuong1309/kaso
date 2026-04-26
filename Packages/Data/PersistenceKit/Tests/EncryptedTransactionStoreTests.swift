import Foundation
import PersistenceKit
import Testing
import TransactionDomain

@Test("saves and fetches transactions from an encrypted file")
func savesAndFetchesTransactions() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL
        .appendingPathComponent("transactions.kasoenc", isDirectory: false)
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let keyData = Data(repeating: 7, count: 32)
    let transaction = Transaction(
        amount: 125_000,
        kind: .expense,
        category: .food,
        occurredAt: Date(timeIntervalSinceReferenceDate: 100),
        note: "sample.transaction.note"
    )
    let store = EncryptedTransactionStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )

    try await store.save(transaction)

    let reloadedStore = EncryptedTransactionStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )
    let transactions = try await reloadedStore.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([transaction])

    #expect(transactions == [transaction])
    #expect(rawData != plainData)
}

@Test("upserts transactions and returns newest first")
func upsertsAndSortsTransactions() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL
        .appendingPathComponent("transactions.kasoenc", isDirectory: false)
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let keyData = Data(repeating: 9, count: 32)
    let transactionID = UUID()
    let oldTransaction = Transaction(
        id: transactionID,
        amount: 50_000,
        kind: .expense,
        category: .transport,
        occurredAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let newerTransaction = Transaction(
        amount: 12_000_000,
        kind: .income,
        category: .salary,
        occurredAt: Date(timeIntervalSinceReferenceDate: 200)
    )
    let updatedTransaction = Transaction(
        id: transactionID,
        amount: 65_000,
        kind: .expense,
        category: .transport,
        occurredAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let store = EncryptedTransactionStore(
        fileURL: fileURL,
        keyDataProvider: { keyData }
    )

    try await store.save(oldTransaction)
    try await store.save(newerTransaction)
    try await store.save(updatedTransaction)

    let transactions = try await store.fetchAll()

    #expect(transactions.count == 2)
    #expect(transactions.first?.id == newerTransaction.id)
    #expect(transactions.last == updatedTransaction)
}
