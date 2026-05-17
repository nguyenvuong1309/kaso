import CryptoKit
import Foundation
import RegretScoreDomain

public enum EncryptedRegretRatingStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedRegretRatingStore {
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
                service: "com.vuongnguyen.kaso.regret-ratings",
                account: "regret-ratings-encryption-key"
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

    public func fetchAll() throws -> [RegretRating] {
        try loadRatings().sorted { $0.ratedAt > $1.ratedAt }
    }

    public func save(_ rating: RegretRating) throws {
        var ratings = try loadRatings()
        ratings.removeAll { $0.id == rating.id }
        ratings.append(rating)
        try saveAll(ratings)
    }

    public func delete(_ id: UUID) throws {
        var ratings = try loadRatings()
        ratings.removeAll { $0.id == id }
        try saveAll(ratings)
    }

    public nonisolated func repository() -> RegretRatingRepository {
        RegretRatingRepository(
            fetchAll: { try await self.fetchAll() },
            save: { try await self.save($0) },
            delete: { try await self.delete($0) }
        )
    }

    private func loadRatings() throws -> [RegretRating] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([RegretRating].self, from: decryptedData)
    }

    private func saveAll(_ ratings: [RegretRating]) throws {
        let data = try encoder.encode(ratings)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedRegretRatingStoreError.invalidSealedBox
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
            .appendingPathComponent("regret-ratings.kasoenc", isDirectory: false)
    }
}
