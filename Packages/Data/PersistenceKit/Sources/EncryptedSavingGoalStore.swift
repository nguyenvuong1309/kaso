import CryptoKit
import Foundation
import GoalDomain

public enum EncryptedSavingGoalStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedSavingGoalStore {
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
                service: "com.vuongnguyen.kaso.saving-goals",
                account: "saving-goals-encryption-key"
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

    public func fetchAll() throws -> [SavingGoal] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([SavingGoal].self, from: decryptedData)
            .sorted { $0.deadline < $1.deadline }
    }

    public func save(_ goal: SavingGoal) throws {
        var goals = try fetchAll()
        goals.removeAll { $0.id == goal.id }
        goals.append(goal)
        try saveAll(goals.sorted { $0.deadline < $1.deadline })
    }

    public func delete(_ id: UUID) throws {
        var goals = try fetchAll()
        goals.removeAll { $0.id == id }
        try saveAll(goals)
    }

    public nonisolated func repository() -> SavingGoalRepository {
        SavingGoalRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { goal in
                try await self.save(goal)
            },
            delete: { id in
                try await self.delete(id)
            }
        )
    }

    private func saveAll(_ goals: [SavingGoal]) throws {
        let data = try encoder.encode(goals)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedSavingGoalStoreError.invalidSealedBox
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
            .appendingPathComponent("saving-goals.kasoenc", isDirectory: false)
    }
}
