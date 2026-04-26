import CryptoKit
import Foundation
import WealthDomain

public enum EncryptedAssetStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedAssetStore {
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
                service: "com.vuongnguyen.kaso.assets",
                account: "assets-encryption-key"
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

    public func fetchAll() throws -> [Asset] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([Asset].self, from: decryptedData)
            .sortedForDisplay()
    }

    public func save(_ asset: Asset) throws {
        var assets = try fetchAll()
        assets.removeAll { $0.id == asset.id }
        assets.append(asset)
        try saveAll(assets.sortedForDisplay())
    }

    public func delete(_ id: UUID) throws {
        var assets = try fetchAll()
        assets.removeAll { $0.id == id }
        try saveAll(assets.sortedForDisplay())
    }

    public func replaceAutoTracked(_ autoTrackedAssets: [Asset]) throws {
        let manualAssets = try fetchAll().filter { $0.isAutoTracked == false }
        try saveAll((manualAssets + autoTrackedAssets).sortedForDisplay())
    }

    public nonisolated func repository() -> AssetRepository {
        AssetRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { asset in
                try await self.save(asset)
            },
            delete: { id in
                try await self.delete(id)
            },
            replaceAutoTracked: { assets in
                try await self.replaceAutoTracked(assets)
            }
        )
    }

    private func saveAll(_ assets: [Asset]) throws {
        let data = try encoder.encode(assets)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedAssetStoreError.invalidSealedBox
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
            .appendingPathComponent("assets.kasoenc", isDirectory: false)
    }
}

private extension [Asset] {
    func sortedForDisplay() -> [Asset] {
        sorted {
            if $0.type == $1.type {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            } else {
                $0.type.rawValue < $1.type.rawValue
            }
        }
    }
}
