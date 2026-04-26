public struct AuthSessionRepository: Sendable {
    public var load: @Sendable () async throws -> AuthSession?
    public var save: @Sendable (AuthSession) async throws -> Void
    public var clear: @Sendable () async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> AuthSession?,
        save: @escaping @Sendable (AuthSession) async throws -> Void,
        clear: @escaping @Sendable () async throws -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

public extension AuthSessionRepository {
    static let empty = AuthSessionRepository(
        load: { nil },
        save: { _ in },
        clear: {}
    )
}
