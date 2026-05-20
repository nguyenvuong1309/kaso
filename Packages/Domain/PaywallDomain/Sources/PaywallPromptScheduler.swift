import Foundation

/// Persisted state the scheduler uses to decide whether to auto-present the
/// paywall on app launch. Avoids spamming users: only fires once the trial
/// window (14 days from first launch) has elapsed, and respects a 7-day
/// cooldown between prompts so the user can still get back to using the app.
public struct PaywallPromptSchedule: Codable, Equatable, Sendable {
    public var firstLaunchAt: Date?
    public var lastShownAt: Date?
    public var hasUserDismissedPermanently: Bool

    public init(
        firstLaunchAt: Date? = nil,
        lastShownAt: Date? = nil,
        hasUserDismissedPermanently: Bool = false
    ) {
        self.firstLaunchAt = firstLaunchAt
        self.lastShownAt = lastShownAt
        self.hasUserDismissedPermanently = hasUserDismissedPermanently
    }

    public static let initial = PaywallPromptSchedule()
}

public struct PaywallPromptScheduleRepository: Sendable {
    public var load: @Sendable () async throws -> PaywallPromptSchedule
    public var save: @Sendable (PaywallPromptSchedule) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> PaywallPromptSchedule,
        save: @escaping @Sendable (PaywallPromptSchedule) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension PaywallPromptScheduleRepository {
    static let empty = PaywallPromptScheduleRepository(
        load: { .initial },
        save: { _ in }
    )

    static let preview = PaywallPromptScheduleRepository(
        load: { PaywallPromptSchedule(firstLaunchAt: Date().addingTimeInterval(-60 * 60 * 24 * 21)) },
        save: { _ in }
    )
}

public enum PaywallPromptScheduler {
    /// Users get the free tier untouched for this long before the first
    /// auto-prompt. Matches `plan.md` §19: "freemium với paywall thông minh —
    /// upsell sau 2–4 tuần".
    public static let trialPeriod: TimeInterval = 60 * 60 * 24 * 14

    /// Once shown, don't show again for this long, regardless of dismissal.
    public static let cooldown: TimeInterval = 60 * 60 * 24 * 7

    public static func shouldPrompt(
        tier: SubscriptionTier,
        schedule: PaywallPromptSchedule,
        now: Date
    ) -> Bool {
        guard tier == .free else { return false }
        guard schedule.hasUserDismissedPermanently == false else { return false }
        guard let firstLaunch = schedule.firstLaunchAt else { return false }
        guard now.timeIntervalSince(firstLaunch) >= trialPeriod else { return false }
        if let lastShown = schedule.lastShownAt,
           now.timeIntervalSince(lastShown) < cooldown {
            return false
        }
        return true
    }

    public static func recordFirstLaunchIfNeeded(
        in schedule: inout PaywallPromptSchedule,
        now: Date
    ) {
        if schedule.firstLaunchAt == nil {
            schedule.firstLaunchAt = now
        }
    }

    public static func recordPromptShown(
        in schedule: inout PaywallPromptSchedule,
        now: Date
    ) {
        schedule.lastShownAt = now
    }
}
