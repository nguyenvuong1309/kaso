import CryptoKit
import Foundation
import PaywallDomain

public enum EncryptedSubscriptionEntitlementStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedSubscriptionEntitlementStore {
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
                service: "com.vuongnguyen.kaso.paywall",
                account: "paywall-entitlement-encryption-key"
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

    public func load() throws -> SubscriptionEntitlement {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .free
        }
        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(SubscriptionEntitlement.self, from: decryptedData)
    }

    public func save(_ entitlement: SubscriptionEntitlement) throws {
        let data = try encoder.encode(entitlement)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedSubscriptionEntitlementStoreError.invalidSealedBox
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

    public nonisolated func repository() -> SubscriptionEntitlementRepository {
        SubscriptionEntitlementRepository(
            load: { (try? await self.load()) ?? .free },
            save: { try await self.save($0) }
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
            .appendingPathComponent("paywall-entitlement.kasoenc", isDirectory: false)
    }
}
