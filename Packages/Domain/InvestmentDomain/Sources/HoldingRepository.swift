import Foundation

public struct HoldingRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [Holding]
    public var save: @Sendable (Holding) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [Holding],
        save: @escaping @Sendable (Holding) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension HoldingRepository {
    static let empty = HoldingRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}

public struct PriceQuoteRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [PriceQuote]
    public var save: @Sendable (PriceQuote) async throws -> Void
    public var saveMany: @Sendable ([PriceQuote]) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [PriceQuote],
        save: @escaping @Sendable (PriceQuote) async throws -> Void,
        saveMany: @escaping @Sendable ([PriceQuote]) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.saveMany = saveMany
    }
}

public extension PriceQuoteRepository {
    static let empty = PriceQuoteRepository(
        fetchAll: { [] },
        save: { _ in },
        saveMany: { _ in }
    )
}
