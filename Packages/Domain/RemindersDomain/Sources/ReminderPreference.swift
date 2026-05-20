import Foundation

public struct ReminderPreference: Sendable, Equatable, Identifiable {
    public let kind: ReminderKind
    public var isEnabled: Bool
    public var hour: Int   // 0–23, only used when kind.isDailySchedule
    public var minute: Int // 0–59

    public init(
        kind: ReminderKind,
        isEnabled: Bool = false,
        hour: Int = 21,
        minute: Int = 0
    ) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    public var id: String { kind.rawValue }
}

public struct ReminderConfiguration: Sendable, Equatable {
    public var preferences: [ReminderPreference]

    public init(preferences: [ReminderPreference]) {
        self.preferences = preferences
    }

    public static let `default` = ReminderConfiguration(
        preferences: ReminderKind.allCases.map { kind in
            ReminderPreference(
                kind: kind,
                isEnabled: false,
                hour: kind == .noSpendStreak ? 20 : 21,
                minute: 0
            )
        }
    )

    public func preference(for kind: ReminderKind) -> ReminderPreference {
        preferences.first(where: { $0.kind == kind })
            ?? ReminderPreference(kind: kind)
    }

    public mutating func update(_ preference: ReminderPreference) {
        if let index = preferences.firstIndex(where: { $0.kind == preference.kind }) {
            preferences[index] = preference
        } else {
            preferences.append(preference)
        }
    }
}

public struct ReminderRepository: Sendable {
    public var load: @Sendable () async throws -> ReminderConfiguration
    public var save: @Sendable (ReminderConfiguration) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> ReminderConfiguration,
        save: @escaping @Sendable (ReminderConfiguration) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }

    public static let empty = ReminderRepository(
        load: { .default },
        save: { _ in }
    )
}

public enum ReminderAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
}

public struct ReminderScheduler: Sendable {
    public var authorizationStatus: @Sendable () async -> ReminderAuthorizationStatus
    public var requestAuthorization: @Sendable () async -> Bool
    public var apply: @Sendable (ReminderConfiguration) async -> Void

    public init(
        authorizationStatus: @escaping @Sendable () async -> ReminderAuthorizationStatus,
        requestAuthorization: @escaping @Sendable () async -> Bool,
        apply: @escaping @Sendable (ReminderConfiguration) async -> Void
    ) {
        self.authorizationStatus = authorizationStatus
        self.requestAuthorization = requestAuthorization
        self.apply = apply
    }

    public static let empty = ReminderScheduler(
        authorizationStatus: { .notDetermined },
        requestAuthorization: { false },
        apply: { _ in }
    )
}
