import CryptoKit
import Foundation
import HuiTrackerDomain

public enum EncryptedHuiTrackerStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedHuiTrackerStore {
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
                service: "com.vuongnguyen.kaso.hui-tracker",
                account: "hui-tracker-encryption-key"
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

    public func fetchAll() throws -> [HuiGroup] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        let groups = try decoder.decode([HuiGroup].self, from: decryptedData)
        return groups.sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ group: HuiGroup) throws {
        var groups = (try? fetchAll()) ?? []
        groups.removeAll { $0.id == group.id }
        groups.append(group)
        try persist(groups)
    }

    public func delete(_ id: UUID) throws {
        var groups = (try? fetchAll()) ?? []
        groups.removeAll { $0.id == id }
        try persist(groups)
    }

    public nonisolated func repository() -> HuiTrackerRepository {
        HuiTrackerRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func persist(_ groups: [HuiGroup]) throws {
        let data = try encoder.encode(groups)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedHuiTrackerStoreError.invalidSealedBox
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
            .appendingPathComponent("hui-tracker.kasoenc", isDirectory: false)
    }
}
