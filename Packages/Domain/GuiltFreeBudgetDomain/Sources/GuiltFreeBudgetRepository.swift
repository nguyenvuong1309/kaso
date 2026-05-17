import Foundation

public struct GuiltFreeBudgetRepository: Sendable {
    public var load: @Sendable () async throws -> GuiltFreeBudgetConfiguration
    public var save: @Sendable (GuiltFreeBudgetConfiguration) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> GuiltFreeBudgetConfiguration,
        save: @escaping @Sendable (GuiltFreeBudgetConfiguration) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension GuiltFreeBudgetRepository {
    static let empty = GuiltFreeBudgetRepository(
        load: { GuiltFreeBudgetConfiguration() },
        save: { _ in }
    )
}
