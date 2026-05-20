import BNPLDomain
import CryptoKit
import Foundation

public enum EncryptedBNPLStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedBNPLStore {
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
                service: "com.vuongnguyen.kaso.bnpl",
                account: "bnpl-encryption-key"
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

    public func fetchAll() throws -> [BNPLObligation] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        let obligations = try decoder.decode([BNPLObligation].self, from: decryptedData)
        return obligations.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    public func save(_ obligation: BNPLObligation) throws {
        var obligations = (try? fetchAll()) ?? []
        obligations.removeAll { $0.id == obligation.id }
        obligations.append(obligation)
        try persist(obligations)
    }

    public func delete(_ id: UUID) throws {
        var obligations = (try? fetchAll()) ?? []
        obligations.removeAll { $0.id == id }
        try persist(obligations)
    }

    public nonisolated func repository() -> BNPLRepository {
        BNPLRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func persist(_ obligations: [BNPLObligation]) throws {
        let data = try encoder.encode(obligations)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedBNPLStoreError.invalidSealedBox
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
            .appendingPathComponent("bnpl.kasoenc", isDirectory: false)
    }
}
