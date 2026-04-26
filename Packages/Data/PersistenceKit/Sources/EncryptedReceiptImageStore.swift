import CryptoKit
import Foundation
import TransactionDomain

public enum EncryptedReceiptImageStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedReceiptImageStore {
    public typealias KeyDataProvider = @Sendable () throws -> Data
    public typealias IdentifierProvider = @Sendable () -> String

    private let directoryURL: URL
    private let keyDataProvider: KeyDataProvider
    private let identifierProvider: IdentifierProvider
    private let fileManager: FileManager

    public init(
        directoryURL: URL? = nil,
        keyDataProvider: @escaping KeyDataProvider = {
            try KeychainSymmetricKeyStore(
                service: "com.vuongnguyen.kaso.receipts",
                account: "receipt-images-encryption-key"
            ).loadOrCreateKeyData()
        },
        identifierProvider: @escaping IdentifierProvider = {
            UUID().uuidString
        },
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL(fileManager: fileManager)
        self.keyDataProvider = keyDataProvider
        self.identifierProvider = identifierProvider
        self.fileManager = fileManager
    }

    public func save(_ imageData: Data) throws -> String {
        let identifier = identifierProvider()
        let sealedBox = try AES.GCM.seal(imageData, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedReceiptImageStoreError.invalidSealedBox
        }

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        #if os(iOS)
        try encryptedData.write(
            to: fileURL(for: identifier),
            options: [.atomic, .completeFileProtection]
        )
        #else
        try encryptedData.write(to: fileURL(for: identifier), options: [.atomic])
        #endif

        return identifier
    }

    public nonisolated func repository() -> ReceiptImageRepository {
        ReceiptImageRepository(
            save: { data in
                try await self.save(data)
            }
        )
    }

    private func fileURL(for identifier: String) -> URL {
        directoryURL.appendingPathComponent("\(identifier).kasoenc", isDirectory: false)
    }

    private func encryptionKey() throws -> SymmetricKey {
        SymmetricKey(data: try keyDataProvider())
    }

    private static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent("Kaso", isDirectory: true)
            .appendingPathComponent("Receipts", isDirectory: true)
    }
}
