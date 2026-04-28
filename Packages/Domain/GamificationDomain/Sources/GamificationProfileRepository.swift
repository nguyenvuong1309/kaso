import Foundation

public struct GamificationProfileRepository: Sendable {
    public var load: @Sendable () async throws -> GamificationProfile?
    public var save: @Sendable (GamificationProfile) async throws -> Void
    public var clear: @Sendable () async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> GamificationProfile?,
        save: @escaping @Sendable (GamificationProfile) async throws -> Void,
        clear: @escaping @Sendable () async throws -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

public extension GamificationProfileRepository {
    static let empty = GamificationProfileRepository(
        load: { nil },
        save: { _ in },
        clear: {}
    )
}
