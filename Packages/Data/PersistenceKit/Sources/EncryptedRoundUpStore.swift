import CryptoKit
import Foundation
import RoundUpDomain

public enum EncryptedRoundUpStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

private struct RoundUpStoreBlob: Codable {
    var rule: RoundUpRule
    var entries: [RoundUpEntry]
}

public actor EncryptedRoundUpStore {
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
                service: "com.vuongnguyen.kaso.round-up",
                account: "round-up-encryption-key"
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

    public func loadRule() throws -> RoundUpRule {
        try loadBlob().rule
    }

    public func saveRule(_ rule: RoundUpRule) throws {
        var blob = try loadBlob()
        blob.rule = rule
        try saveBlob(blob)
    }

    public func fetchEntries() throws -> [RoundUpEntry] {
        try loadBlob().entries.sorted { $0.createdAt > $1.createdAt }
    }

    public func saveEntry(_ entry: RoundUpEntry) throws {
        var blob = try loadBlob()
        blob.entries.removeAll { $0.id == entry.id }
        blob.entries.append(entry)
        try saveBlob(blob)
    }

    public func deleteEntry(_ id: UUID) throws {
        var blob = try loadBlob()
        blob.entries.removeAll { $0.id == id }
        try saveBlob(blob)
    }

    public func clearAll() throws {
        var blob = try loadBlob()
        blob.entries.removeAll()
        try saveBlob(blob)
    }

    public nonisolated func repository() -> RoundUpRepository {
        RoundUpRepository(
            loadRule: { try await self.loadRule() },
            saveRule: { try await self.saveRule($0) },
            fetchEntries: { try await self.fetchEntries() },
            saveEntry: { try await self.saveEntry($0) },
            deleteEntry: { try await self.deleteEntry($0) },
            clearAll: { try await self.clearAll() }
        )
    }

    private func loadBlob() throws -> RoundUpStoreBlob {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return RoundUpStoreBlob(rule: RoundUpRule(), entries: [])
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(RoundUpStoreBlob.self, from: decryptedData)
    }

    private func saveBlob(_ blob: RoundUpStoreBlob) throws {
        let data = try encoder.encode(blob)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedRoundUpStoreError.invalidSealedBox
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
            .appendingPathComponent("round-up.kasoenc", isDirectory: false)
    }
}
