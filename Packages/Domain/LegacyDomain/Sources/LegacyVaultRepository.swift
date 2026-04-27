public struct LegacyVaultRepository: Sendable {
    public var load: @Sendable () async throws -> LegacyVault?
    public var save: @Sendable (LegacyVault) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> LegacyVault?,
        save: @escaping @Sendable (LegacyVault) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension LegacyVaultRepository {
    static let empty = LegacyVaultRepository(
        load: { nil },
        save: { _ in }
    )
}
