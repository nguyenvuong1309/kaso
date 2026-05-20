#if canImport(UserNotifications)
import Foundation
import RemindersDomain
import UserNotifications

public extension ReminderScheduler {
    /// Live `UNUserNotificationCenter` implementation. Notifications use
    /// localized title/body keys from this module's resources so no PII reaches
    /// the system payload.
    static let live = ReminderScheduler(
        authorizationStatus: { @Sendable in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .authorized: return .authorized
            case .provisional: return .provisional
            case .ephemeral: return .authorized
            @unknown default: return .notDetermined
            }
        },
        requestAuthorization: { @Sendable in
            let center = UNUserNotificationCenter.current()
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                return false
            }
        },
        apply: { @Sendable configuration in
            let center = UNUserNotificationCenter.current()
            let bundleIdentifierPrefix = "com.vuongnguyen.kaso.reminder."
            let allIdentifiers = configuration.preferences.map { bundleIdentifierPrefix + $0.kind.rawValue }
            center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

            for preference in configuration.preferences where preference.isEnabled && preference.kind.isDailySchedule {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString(
                    preference.kind.notificationTitleKey,
                    bundle: .module,
                    comment: ""
                )
                content.body = NSLocalizedString(
                    preference.kind.notificationBodyKey,
                    bundle: .module,
                    comment: ""
                )
                content.sound = .default

                var components = DateComponents()
                components.hour = preference.hour
                components.minute = preference.minute
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )

                let request = UNNotificationRequest(
                    identifier: bundleIdentifierPrefix + preference.kind.rawValue,
                    content: content,
                    trigger: trigger
                )

                _ = try? await center.add(request)
            }
        }
    )
}
#else
import Foundation
import RemindersDomain

public extension ReminderScheduler {
    static let live = ReminderScheduler.empty
}
#endif
