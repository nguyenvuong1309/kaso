import Foundation

public struct SavingGoalRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [SavingGoal]
    public var save: @Sendable (SavingGoal) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [SavingGoal],
        save: @escaping @Sendable (SavingGoal) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
    }
}

public extension SavingGoalRepository {
    static let empty = SavingGoalRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
