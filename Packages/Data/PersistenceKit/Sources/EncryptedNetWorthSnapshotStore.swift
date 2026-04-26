import CryptoKit
import Foundation
import WealthDomain

public enum EncryptedNetWorthSnapshotStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedNetWorthSnapshotStore {
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
                service: "com.vuongnguyen.kaso.net-worth",
                account: "net-worth-snapshots-encryption-key"
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

    public func fetchAll() throws -> [NetWorthSnapshot] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([NetWorthSnapshot].self, from: decryptedData)
            .sorted { $0.date < $1.date }
    }

    public func save(_ snapshot: NetWorthSnapshot) throws {
        var snapshots = try fetchAll()
        snapshots.removeAll { $0.id == snapshot.id }
        snapshots.append(snapshot)
        try saveAll(snapshots.sorted { $0.date < $1.date })
    }

    public func prune(before cutoffDate: Date) throws {
        let snapshots = try fetchAll().filter { $0.date >= cutoffDate }
        try saveAll(snapshots)
    }

    public nonisolated func repository() -> NetWorthSnapshotRepository {
        NetWorthSnapshotRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { snapshot in
                try await self.save(snapshot)
            },
            prune: { cutoffDate in
                try await self.prune(before: cutoffDate)
            }
        )
    }

    private func saveAll(_ snapshots: [NetWorthSnapshot]) throws {
        let data = try encoder.encode(snapshots)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedNetWorthSnapshotStoreError.invalidSealedBox
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
            .appendingPathComponent("net-worth-snapshots.kasoenc", isDirectory: false)
    }
}
