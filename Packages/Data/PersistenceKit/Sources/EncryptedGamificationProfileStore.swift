import CryptoKit
import Foundation
import GamificationDomain

public enum EncryptedGamificationProfileStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedGamificationProfileStore {
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
                service: "com.vuongnguyen.kaso.gamification",
                account: "gamification-profile-encryption-key"
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

    public func load() throws -> GamificationProfile? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(GamificationProfile.self, from: decryptedData)
    }

    public func save(_ profile: GamificationProfile) throws {
        let data = try encoder.encode(profile)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedGamificationProfileStoreError.invalidSealedBox
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

    public func clear() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }

    public nonisolated func repository() -> GamificationProfileRepository {
        GamificationProfileRepository(
            load: {
                try await self.load()
            },
            save: { profile in
                try await self.save(profile)
            },
            clear: {
                try await self.clear()
            }
        )
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
            .appendingPathComponent("gamification-profile.kasoenc", isDirectory: false)
    }
}
