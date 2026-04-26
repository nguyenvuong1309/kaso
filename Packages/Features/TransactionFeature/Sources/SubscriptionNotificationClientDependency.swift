import Foundation
import ComposableArchitecture
import SubscriptionDomain

#if canImport(UserNotifications)
import UserNotifications
#endif

public struct SubscriptionNotificationClient: Sendable {
    public var scheduleRenewalReminders: @Sendable ([SubscriptionRenewalReminder]) async throws -> Void

    public init(
        scheduleRenewalReminders: @escaping @Sendable ([SubscriptionRenewalReminder]) async throws -> Void
    ) {
        self.scheduleRenewalReminders = scheduleRenewalReminders
    }
}

public extension SubscriptionNotificationClient {
    static let noop = SubscriptionNotificationClient(
        scheduleRenewalReminders: { _ in }
    )

    static let live = SubscriptionNotificationClient(
        scheduleRenewalReminders: { reminders in
            #if canImport(UserNotifications)
            guard reminders.isEmpty == false else {
                return
            }

            let center = UNUserNotificationCenter.current()
            let isAuthorized = try await center.requestAuthorization(options: [.alert, .sound])
            guard isAuthorized else {
                return
            }

            let reminderIDs = Set(reminders.map(\.id))
            let staleReminderIDs = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { identifier in
                    identifier.hasPrefix("subscription-renewal-")
                        && reminderIDs.contains(identifier) == false
                }
            center.removePendingNotificationRequests(
                withIdentifiers: staleReminderIDs + Array(reminderIDs)
            )

            for reminder in reminders {
                let content = UNMutableNotificationContent()
                content.title = String(
                    localized: "transactions.subscription.notification.title",
                    bundle: .module
                )
                content.body = String(
                    localized: "transactions.subscription.notification.body",
                    bundle: .module
                )
                content.sound = .default

                let dateComponents = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: reminder.notificationDate
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: reminder.id,
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
            #else
            _ = reminders
            #endif
        }
    )
}

private enum SubscriptionNotificationClientKey: DependencyKey {
    static let liveValue = SubscriptionNotificationClient.live
    static let previewValue = SubscriptionNotificationClient.noop
    static let testValue = SubscriptionNotificationClient.noop
}

public extension DependencyValues {
    var subscriptionNotificationClient: SubscriptionNotificationClient {
        get { self[SubscriptionNotificationClientKey.self] }
        set { self[SubscriptionNotificationClientKey.self] = newValue }
    }
}
