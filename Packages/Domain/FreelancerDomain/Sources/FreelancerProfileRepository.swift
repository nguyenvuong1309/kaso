public struct FreelancerProfileRepository: Sendable {
    public var load: @Sendable () async throws -> FreelancerProfile?
    public var save: @Sendable (FreelancerProfile) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> FreelancerProfile?,
        save: @escaping @Sendable (FreelancerProfile) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension FreelancerProfileRepository {
    static let empty = FreelancerProfileRepository(
        load: { nil },
        save: { _ in }
    )
}
