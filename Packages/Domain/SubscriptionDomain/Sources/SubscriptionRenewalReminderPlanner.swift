import Foundation

public struct SubscriptionRenewalReminder: Identifiable, Equatable, Sendable {
    public let id: String
    public let subscriptionID: String
    public let notificationDate: Date
    public let renewalDate: Date
    public let dayCountUntilRenewal: Int

    public init(
        id: String,
        subscriptionID: String,
        notificationDate: Date,
        renewalDate: Date,
        dayCountUntilRenewal: Int
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.notificationDate = notificationDate
        self.renewalDate = renewalDate
        self.dayCountUntilRenewal = dayCountUntilRenewal
    }
}

public enum SubscriptionRenewalReminderPlanner {
    public static func reminders(
        for subscriptions: [DetectedSubscription],
        referenceDate: Date = Date(),
        leadDays: Int = 3,
        dueSoonDayLimit: Int = 5,
        fallbackDelayHours: Int = 1,
        calendar: Calendar = .current
    ) -> [SubscriptionRenewalReminder] {
        subscriptions.compactMap { subscription in
            reminder(
                for: subscription,
                referenceDate: referenceDate,
                leadDays: leadDays,
                dueSoonDayLimit: dueSoonDayLimit,
                fallbackDelayHours: fallbackDelayHours,
                calendar: calendar
            )
        }
        .sorted { lhs, rhs in
            if lhs.notificationDate == rhs.notificationDate {
                return lhs.renewalDate < rhs.renewalDate
            }

            return lhs.notificationDate < rhs.notificationDate
        }
    }

    private static func reminder(
        for subscription: DetectedSubscription,
        referenceDate: Date,
        leadDays: Int,
        dueSoonDayLimit: Int,
        fallbackDelayHours: Int,
        calendar: Calendar
    ) -> SubscriptionRenewalReminder? {
        let dayCount = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: referenceDate),
            to: calendar.startOfDay(for: subscription.nextBillingDate)
        ).day

        guard let dayCount,
              (0 ... dueSoonDayLimit).contains(dayCount) else {
            return nil
        }

        let preferredNotificationDate = calendar.date(
            byAdding: .day,
            value: -leadDays,
            to: subscription.nextBillingDate
        ) ?? subscription.nextBillingDate
        let fallbackNotificationDate = calendar.date(
            byAdding: .hour,
            value: fallbackDelayHours,
            to: referenceDate
        ) ?? referenceDate
        let notificationDate = max(preferredNotificationDate, fallbackNotificationDate)

        return SubscriptionRenewalReminder(
            id: identifier(for: subscription, renewalDate: subscription.nextBillingDate, calendar: calendar),
            subscriptionID: subscription.id,
            notificationDate: notificationDate,
            renewalDate: subscription.nextBillingDate,
            dayCountUntilRenewal: dayCount
        )
    }

    private static func identifier(
        for subscription: DetectedSubscription,
        renewalDate: Date,
        calendar: Calendar
    ) -> String {
        let sourceID = subscription.transactionIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: "-")
        let stableSourceID = sourceID.isEmpty ? subscription.interval.rawValue : sourceID
        let components = calendar.dateComponents([.year, .month, .day], from: renewalDate)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0

        return "subscription-renewal-\(stableSourceID)-\(String(format: "%04d%02d%02d", year, month, day))"
    }
}
