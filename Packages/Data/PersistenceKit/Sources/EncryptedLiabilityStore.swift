import CryptoKit
import Foundation
import WealthDomain

public enum EncryptedLiabilityStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedLiabilityStore {
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
                service: "com.vuongnguyen.kaso.liabilities",
                account: "liabilities-encryption-key"
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

    public func fetchAll() throws -> [Liability] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([Liability].self, from: decryptedData)
            .sortedForDisplay()
    }

    public func save(_ liability: Liability) throws {
        var liabilities = try fetchAll()
        liabilities.removeAll { $0.id == liability.id }
        liabilities.append(liability)
        try saveAll(liabilities.sortedForDisplay())
    }

    public func delete(_ id: UUID) throws {
        var liabilities = try fetchAll()
        liabilities.removeAll { $0.id == id }
        try saveAll(liabilities.sortedForDisplay())
    }

    public func replaceAutoTracked(_ autoTrackedLiabilities: [Liability]) throws {
        let manualLiabilities = try fetchAll().filter { $0.isAutoTracked == false }
        try saveAll((manualLiabilities + autoTrackedLiabilities).sortedForDisplay())
    }

    public nonisolated func repository() -> LiabilityRepository {
        LiabilityRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { liability in
                try await self.save(liability)
            },
            delete: { id in
                try await self.delete(id)
            },
            replaceAutoTracked: { liabilities in
                try await self.replaceAutoTracked(liabilities)
            }
        )
    }

    private func saveAll(_ liabilities: [Liability]) throws {
        let data = try encoder.encode(liabilities)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedLiabilityStoreError.invalidSealedBox
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
            .appendingPathComponent("liabilities.kasoenc", isDirectory: false)
    }
}

private extension [Liability] {
    func sortedForDisplay() -> [Liability] {
        sorted {
            if $0.type == $1.type {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            } else {
                $0.type.rawValue < $1.type.rawValue
            }
        }
    }
}
