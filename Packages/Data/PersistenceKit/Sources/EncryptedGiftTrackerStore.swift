import CryptoKit
import Foundation
import GiftTrackerDomain

public enum EncryptedGiftTrackerStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedGiftTrackerStore {
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
                service: "com.vuongnguyen.kaso.gift-tracker",
                account: "gift-tracker-encryption-key"
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

    public func fetchAll() throws -> [GiftRecord] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        let records = try decoder.decode([GiftRecord].self, from: decryptedData)
        return records.sorted { $0.eventDate > $1.eventDate }
    }

    public func save(_ record: GiftRecord) throws {
        var records = (try? fetchAll()) ?? []
        records.removeAll { $0.id == record.id }
        records.append(record)
        try persist(records)
    }

    public func delete(_ id: UUID) throws {
        var records = (try? fetchAll()) ?? []
        records.removeAll { $0.id == id }
        try persist(records)
    }

    public nonisolated func repository() -> GiftTrackerRepository {
        GiftTrackerRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func persist(_ records: [GiftRecord]) throws {
        let data = try encoder.encode(records)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedGiftTrackerStoreError.invalidSealedBox
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
            .appendingPathComponent("gift-tracker.kasoenc", isDirectory: false)
    }
}
