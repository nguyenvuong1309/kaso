import CryptoKit
import Foundation
import MoodJournalDomain

public enum EncryptedMoodJournalStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedMoodJournalStore {
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
                service: "com.vuongnguyen.kaso.mood-journal",
                account: "mood-journal-encryption-key"
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

    public func fetchAll() throws -> [MoodEntry] {
        try loadEntries().sorted { $0.recordedAt > $1.recordedAt }
    }

    public func save(_ entry: MoodEntry) throws {
        var entries = try loadEntries()
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        try saveAll(entries)
    }

    public func delete(_ id: UUID) throws {
        var entries = try loadEntries()
        entries.removeAll { $0.id == id }
        try saveAll(entries)
    }

    public nonisolated func repository() -> MoodJournalRepository {
        MoodJournalRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func loadEntries() throws -> [MoodEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([MoodEntry].self, from: decryptedData)
    }

    private func saveAll(_ entries: [MoodEntry]) throws {
        let data = try encoder.encode(entries)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedMoodJournalStoreError.invalidSealedBox
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
            .appendingPathComponent("mood-journal.kasoenc", isDirectory: false)
    }
}
