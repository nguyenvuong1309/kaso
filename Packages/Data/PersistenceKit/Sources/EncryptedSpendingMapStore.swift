import CryptoKit
import Foundation
import SpendingMapDomain

public enum EncryptedSpendingMapStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedSpendingMapStore {
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
                service: "com.vuongnguyen.kaso.spending-map",
                account: "spending-map-encryption-key"
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

    public func fetchAll() throws -> [SpendingMapEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        let entries = try decoder.decode([SpendingMapEntry].self, from: decryptedData)
        return entries.sorted { $0.occurredAt > $1.occurredAt }
    }

    public func save(_ entry: SpendingMapEntry) throws {
        var entries = (try? fetchAll()) ?? []
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        try persist(entries)
    }

    public func delete(_ id: UUID) throws {
        var entries = (try? fetchAll()) ?? []
        entries.removeAll { $0.id == id }
        try persist(entries)
    }

    public nonisolated func repository() -> SpendingMapRepository {
        SpendingMapRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func persist(_ entries: [SpendingMapEntry]) throws {
        let data = try encoder.encode(entries)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedSpendingMapStoreError.invalidSealedBox
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
            .appendingPathComponent("spending-map.kasoenc", isDirectory: false)
    }
}
