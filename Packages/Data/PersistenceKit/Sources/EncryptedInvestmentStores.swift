import CryptoKit
import Foundation
import InvestmentDomain

public enum EncryptedInvestmentStoreError: Error, Equatable, Sendable {
    case invalidSealedBox
}

public actor EncryptedHoldingStore {
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
                service: "com.vuongnguyen.kaso.investment-holdings",
                account: "investment-holdings-encryption-key"
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

    public func fetchAll() throws -> [Holding] {
        try loadHoldings().sortedForDisplay()
    }

    public func save(_ holding: Holding) throws {
        var holdings = try loadHoldings()
        holdings.removeAll { $0.id == holding.id }
        holdings.append(holding)
        try saveAll(holdings.sortedForDisplay())
    }

    public func delete(_ id: UUID) throws {
        var holdings = try loadHoldings()
        holdings.removeAll { $0.id == id }
        try saveAll(holdings.sortedForDisplay())
    }

    public nonisolated func repository() -> HoldingRepository {
        HoldingRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { holding in
                try await self.save(holding)
            },
            delete: { id in
                try await self.delete(id)
            }
        )
    }

    private func loadHoldings() throws -> [Holding] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([Holding].self, from: decryptedData)
    }

    private func saveAll(_ holdings: [Holding]) throws {
        let data = try encoder.encode(holdings)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedInvestmentStoreError.invalidSealedBox
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
        defaultDirectory(fileManager: fileManager)
            .appendingPathComponent("investment-holdings.kasoenc", isDirectory: false)
    }
}

public actor EncryptedPriceQuoteStore {
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
                service: "com.vuongnguyen.kaso.investment-quotes",
                account: "investment-quotes-encryption-key"
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

    public func fetchAll() throws -> [PriceQuote] {
        try loadQuotes().sorted { $0.symbol < $1.symbol }
    }

    public func save(_ quote: PriceQuote) throws {
        var quotes = try loadQuotes()
        quotes.removeAll { $0.symbol.caseInsensitiveCompare(quote.symbol) == .orderedSame }
        quotes.append(quote)
        try saveAll(quotes.sorted { $0.symbol < $1.symbol })
    }

    public func saveMany(_ quotes: [PriceQuote]) throws {
        var storedQuotes = try loadQuotes()
        for quote in quotes {
            storedQuotes.removeAll { $0.symbol.caseInsensitiveCompare(quote.symbol) == .orderedSame }
            storedQuotes.append(quote)
        }
        try saveAll(storedQuotes.sorted { $0.symbol < $1.symbol })
    }

    public nonisolated func repository() -> PriceQuoteRepository {
        PriceQuoteRepository(
            fetchAll: {
                try await self.fetchAll()
            },
            save: { quote in
                try await self.save(quote)
            },
            saveMany: { quotes in
                try await self.saveMany(quotes)
            }
        )
    }

    private func loadQuotes() throws -> [PriceQuote] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode([PriceQuote].self, from: decryptedData)
    }

    private func saveAll(_ quotes: [PriceQuote]) throws {
        let data = try encoder.encode(quotes)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedInvestmentStoreError.invalidSealedBox
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
        defaultDirectory(fileManager: fileManager)
            .appendingPathComponent("investment-quotes.kasoenc", isDirectory: false)
    }
}

public actor EncryptedTargetAllocationStore {
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
                service: "com.vuongnguyen.kaso.target-allocation",
                account: "target-allocation-encryption-key"
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

    public func load() throws -> TargetAllocation {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey())
        return try decoder.decode(TargetAllocation.self, from: decryptedData)
    }

    public func save(_ target: TargetAllocation) throws {
        let data = try encoder.encode(target)
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey())
        guard let encryptedData = sealedBox.combined else {
            throw EncryptedInvestmentStoreError.invalidSealedBox
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

    public nonisolated func repository() -> TargetAllocationRepository {
        TargetAllocationRepository(
            load: {
                try await self.load()
            },
            save: { target in
                try await self.save(target)
            }
        )
    }

    private func encryptionKey() throws -> SymmetricKey {
        SymmetricKey(data: try keyDataProvider())
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        defaultDirectory(fileManager: fileManager)
            .appendingPathComponent("target-allocation.kasoenc", isDirectory: false)
    }
}

private func defaultDirectory(fileManager: FileManager) -> URL {
    let applicationSupportURL = fileManager
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first ?? fileManager.temporaryDirectory

    return applicationSupportURL.appendingPathComponent("Kaso", isDirectory: true)
}

private extension [Holding] {
    func sortedForDisplay() -> [Holding] {
        sorted {
            if $0.assetClass == $1.assetClass {
                $0.symbol.localizedCaseInsensitiveCompare($1.symbol) == .orderedAscending
            } else {
                $0.assetClass.rawValue < $1.assetClass.rawValue
            }
        }
    }
}
