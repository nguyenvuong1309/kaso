import Foundation

public enum ReminderKind: String, CaseIterable, Sendable, Equatable, Identifiable {
    case endOfDayEntry
    case budgetNearLimit
    case subscriptionRenewal
    case noSpendStreak
    case largeExpense

    public var id: String { rawValue }

    public var titleKey: String { "reminders.kind.\(rawValue).title" }
    public var descriptionKey: String { "reminders.kind.\(rawValue).description" }
    public var notificationTitleKey: String { "reminders.kind.\(rawValue).notification.title" }
    public var notificationBodyKey: String { "reminders.kind.\(rawValue).notification.body" }

    public var iconSystemName: String {
        switch self {
        case .endOfDayEntry: "moon.stars"
        case .budgetNearLimit: "exclamationmark.gauge"
        case .subscriptionRenewal: "calendar.badge.clock"
        case .noSpendStreak: "flame"
        case .largeExpense: "bell.badge"
        }
    }

    /// Whether the reminder uses a daily fixed-hour schedule (true) or is fired
    /// in response to events from elsewhere in the app (false).
    public var isDailySchedule: Bool {
        switch self {
        case .endOfDayEntry, .noSpendStreak: true
        case .budgetNearLimit, .subscriptionRenewal, .largeExpense: false
        }
    }
}
