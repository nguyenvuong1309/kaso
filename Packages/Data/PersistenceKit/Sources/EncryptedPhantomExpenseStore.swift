import CryptoKit
import Foundation
import PhantomExpenseDomain

public enum EncryptedPhantomExpenseStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedPhantomExpenseStore {
    public typealias KeyDataProvider = @Sendable () throws -> Data

    private let fileURL: URL
    private let keyDataProvider: KeyDataProvider
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL? = nil,
        keyDataProvider: @escaping KeyDataProvider = {
            try KeychainSymmetricKeyStore(
                service: "com.vuongnguyen.kaso.phantom-expenses",
                account: "phantom-expenses-encryption-key"
            ).loadOrCreateKeyData()
        },
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.keyDataProvider = keyDataProvider
        self.fileManager = fileManager
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    public func fetchAll() throws -> [PhantomExpense] {
        try loadExpenses().sortedForDisplay()
    }

    public func save(_ expense: PhantomExpense) throws {
        var expenses = try loadExpenses()
        expenses.removeAll { $0.id == expense.id }
        expenses.append(expense)
        try saveAll(expenses.sortedForDisplay())
    }

    public func delete(_ id: UUID) throws {
        var expenses = try loadExpenses()
        expenses.removeAll { $0.id == id }
        try saveAll(expenses.sortedForDisplay())
    }

    public nonisolated func repository() -> PhantomExpenseRepository {
        PhantomExpenseRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { expense in
                try await self.save(expense)
            },
            delete: { id in
                try await self.delete(id)
            }
        )
    }

    private func loadExpenses() throws -> [PhantomExpense] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([PhantomExpense].self, from: decryptedData)
    }

    private func saveAll(_ expenses: [PhantomExpense]) throws {
        let data = try encoder.encode(expenses)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedPhantomExpenseStoreError.invalidSealedBox
        }

        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        #if os(iOS)
        try encryptedData.write(to: fileURL, options: [.atomic, .completeFileProtection])
        #else
        try encryptedData.write(to: fileURL, options: [.atomic])
        #endif
    }

    private func encryptionKey() throws -> SymmetricKey {
        SymmetricKey(data: try keyDataProvider())
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent("Kaso", isDirectory: true)
            .appendingPathComponent("phantom-expenses.kasoenc", isDirectory: false)
    }
}

private extension [PhantomExpense] {
    func sortedForDisplay() -> [PhantomExpense] {
        sorted {
            if $0.avoidedAt == $1.avoidedAt {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            } else {
                $0.avoidedAt > $1.avoidedAt
            }
        }
    }
}
