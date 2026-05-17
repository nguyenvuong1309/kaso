import CoolingOffDomain
import CryptoKit
import Foundation

public enum EncryptedPurchasePlanStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

private struct PurchasePlanStoreBlob: Codable {
    var policy: CoolingOffPolicy
    var plans: [PurchasePlan]
}

public actor EncryptedPurchasePlanStore {
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
                service: "com.vuongnguyen.kaso.cooling-off",
                account: "cooling-off-encryption-key"
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

    public func fetchAll() throws -> [PurchasePlan] {
        try loadBlob().plans.sorted { $0.availableAt < $1.availableAt }
    }

    public func save(_ plan: PurchasePlan) throws {
        var blob = try loadBlob()
        blob.plans.removeAll { $0.id == plan.id }
        blob.plans.append(plan)
        try saveBlob(blob)
    }

    public func delete(_ id: UUID) throws {
        var blob = try loadBlob()
        blob.plans.removeAll { $0.id == id }
        try saveBlob(blob)
    }

    public func loadPolicy() throws -> CoolingOffPolicy {
        try loadBlob().policy
    }

    public func savePolicy(_ policy: CoolingOffPolicy) throws {
        var blob = try loadBlob()
        blob.policy = policy
        try saveBlob(blob)
    }

    public nonisolated func repository() -> PurchasePlanRepository {
        PurchasePlanRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) },
            loadPolicy: { try await self.loadPolicy() },
            savePolicy: { try await self.savePolicy($0) }
        )
    }

    private func loadBlob() throws -> PurchasePlanStoreBlob {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return PurchasePlanStoreBlob(policy: .default, plans: [])
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(PurchasePlanStoreBlob.self, from: decryptedData)
    }

    private func saveBlob(_ blob: PurchasePlanStoreBlob) throws {
        let data = try encoder.encode(blob)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedPurchasePlanStoreError.invalidSealedBox
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
            .appendingPathComponent("cooling-off.kasoenc", isDirectory: false)
    }
}
