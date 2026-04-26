public struct AppearanceSettingsRepository: Sendable {
    public var load: @Sendable () async throws -> AppearanceSettings
    public var save: @Sendable (AppearanceSettings) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> AppearanceSettings,
        save: @escaping @Sendable (AppearanceSettings) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension AppearanceSettingsRepository {
    static let empty = AppearanceSettingsRepository(
        load: { .defaultValue },
        save: { _ in }
    )
}
