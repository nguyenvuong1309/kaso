import CryptoKit
import Foundation
import WellnessDomain

public enum EncryptedHoursOfLifeConfigurationStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedHoursOfLifeConfigurationStore {
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
                service: "com.vuongnguyen.kaso.hours-of-life",
                account: "hours-of-life-encryption-key"
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

    public func load() throws -> HoursOfLifeConfiguration? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(HoursOfLifeConfiguration.self, from: decryptedData)
    }

    public func save(_ configuration: HoursOfLifeConfiguration) throws {
        let data = try encoder.encode(configuration)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedHoursOfLifeConfigurationStoreError.invalidSealedBox
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
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    public nonisolated func repository() -> HoursOfLifeConfigurationRepository {
        HoursOfLifeConfigurationRepository(
            load: {
                try await self.load()
            },
            save: { configuration in
                try await self.save(configuration)
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
            .appendingPathComponent("hours-of-life-configuration.kasoenc", isDirectory: false)
    }
}
