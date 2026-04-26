import Foundation
import CryptoKit
import DebtDomain

public enum EncryptedDebtStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedDebtStore {
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
                service: "com.vuongnguyen.kaso.debts",
                account: "debts-encryption-key"
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

    public func fetchAll() throws -> [Debt] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([Debt].self, from: decryptedData)
            .sortedForDisplay()
    }

    public func save(_ debt: Debt) throws {
        var debts = try fetchAll()
        debts.removeAll { $0.id == debt.id }
        debts.append(debt)
        try saveAll(debts.sortedForDisplay())
    }

    public func delete(_ id: UUID) throws {
        var debts = try fetchAll()
        debts.removeAll { $0.id == id }
        try saveAll(debts.sortedForDisplay())
    }

    public nonisolated func repository() -> DebtRepository {
        DebtRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { debt in
                try await self.save(debt)
            },
            delete: { id in
                try await self.delete(id)
            }
        )
    }

    private func saveAll(_ debts: [Debt]) throws {
        let data = try encoder.encode(debts)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedDebtStoreError.invalidSealedBox
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
            .appendingPathComponent("debts.kasoenc", isDirectory: false)
    }
}

private extension [Debt] {
    func sortedForDisplay() -> [Debt] {
        sorted {
            if $0.createdAt == $1.createdAt {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            } else {
                $0.createdAt < $1.createdAt
            }
        }
    }
}
