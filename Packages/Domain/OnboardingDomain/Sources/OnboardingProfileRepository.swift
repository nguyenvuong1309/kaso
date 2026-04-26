public struct OnboardingProfileRepository: Sendable {
    public var load: @Sendable () async throws -> OnboardingProfile?
    public var save: @Sendable (OnboardingProfile) async throws -> Void
    public var clear: @Sendable () async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> OnboardingProfile?,
        save: @escaping @Sendable (OnboardingProfile) async throws -> Void,
        clear: @escaping @Sendable () async throws -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

public extension OnboardingProfileRepository {
    static let empty = OnboardingProfileRepository(
        load: { nil },
        save: { _ in },
        clear: {}
    )
}
