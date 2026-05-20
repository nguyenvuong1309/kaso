import Foundation

public struct CloudSyncPreferences: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var lastSyncedAt: Date?
    public var syncedKinds: Set<CloudSyncRecord.Kind>

    public init(
        isEnabled: Bool = false,
        lastSyncedAt: Date? = nil,
        syncedKinds: Set<CloudSyncRecord.Kind> = [.transaction, .budget, .category, .savingGoal]
    ) {
        self.isEnabled = isEnabled
        self.lastSyncedAt = lastSyncedAt
        self.syncedKinds = syncedKinds
    }

    public static let `default` = CloudSyncPreferences()
}

public struct CloudSyncPreferencesRepository: Sendable {
    public var load: @Sendable () async throws -> CloudSyncPreferences
    public var save: @Sendable (CloudSyncPreferences) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> CloudSyncPreferences,
        save: @escaping @Sendable (CloudSyncPreferences) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension CloudSyncPreferencesRepository {
    static let empty = CloudSyncPreferencesRepository(
        load: { .default },
        save: { _ in }
    )

    static let preview = CloudSyncPreferencesRepository(
        load: { CloudSyncPreferences(isEnabled: true, lastSyncedAt: Date()) },
        save: { _ in }
    )
}
