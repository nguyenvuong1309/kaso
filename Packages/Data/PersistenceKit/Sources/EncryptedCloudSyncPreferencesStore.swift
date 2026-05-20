import CloudSyncDomain
import CryptoKit
import Foundation

public actor EncryptedCloudSyncPreferencesStore {
    public typealias KeyDataProvider = @Sendable () throws -> Data

    private let fileURL: URL
    private let keyDataProvider: KeyDataProvider
    private let fileManager: FileManager

    public init(
        fileURL: URL? = nil,
        keyDataProvider: @escaping KeyDataProvider = {
            try KeychainSymmetricKeyStore(
                service: "com.vuongnguyen.kaso.cloud-sync",
                account: "cloud-sync-prefs-encryption-key"
            ).loadOrCreateKeyData()
        },
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        self.keyDataProvider = keyDataProvider
        self.fileManager = fileManager
    }

    public func load() throws -> CloudSyncPreferences {
        guard fileManager.fileExists(atPath: fileURL.path) else { return .default }
        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let key = SymmetricKey(data: try keyDataProvider())
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        return try JSONDecoder().decode(CloudSyncPreferences.self, from: decrypted)
    }

    public func save(_ prefs: CloudSyncPreferences) throws {
        let data = try JSONEncoder().encode(prefs)
        let key = SymmetricKey(data: try keyDataProvider())
        let sealed = try AES.GCM.seal(data, using: key)
        guard let encryptedData = sealed.combined else { return }
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

    public nonisolated func repository() -> CloudSyncPreferencesRepository {
        CloudSyncPreferencesRepository(
            load: { (try? await self.load()) ?? .default },
            save: { try await self.save($0) }
        )
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? fileManager.temporaryDirectory
        return applicationSupportURL
            .appendingPathComponent("Kaso", isDirectory: true)
            .appendingPathComponent("cloud-sync-prefs.kasoenc", isDirectory: false)
    }
}
