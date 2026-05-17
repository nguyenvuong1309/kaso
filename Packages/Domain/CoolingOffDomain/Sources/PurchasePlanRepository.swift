import Foundation

public struct PurchasePlanRepository: Sendable {
    public var fetchAll: @Sendable () async throws -> [PurchasePlan]
    public var save: @Sendable (PurchasePlan) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void
    public var loadPolicy: @Sendable () async throws -> CoolingOffPolicy
    public var savePolicy: @Sendable (CoolingOffPolicy) async throws -> Void

    public init(
        fetchAll: @escaping @Sendable () async throws -> [PurchasePlan],
        save: @escaping @Sendable (PurchasePlan) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void,
        loadPolicy: @escaping @Sendable () async throws -> CoolingOffPolicy,
        savePolicy: @escaping @Sendable (CoolingOffPolicy) async throws -> Void
    ) {
        self.fetchAll = fetchAll
        self.save = save
        self.delete = delete
        self.loadPolicy = loadPolicy
        self.savePolicy = savePolicy
    }
}

public extension PurchasePlanRepository {
    static let empty = PurchasePlanRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in },
        loadPolicy: { .default },
        savePolicy: { _ in }
    )
}
