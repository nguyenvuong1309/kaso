import Foundation
import Testing
import TransactionDomain
@testable import SubscriptionDomain

@Test("plans renewal reminder three days before billing")
func plansRenewalReminderThreeDaysBeforeBilling() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 26, hour: 9, calendar: calendar)
    let renewalDate = try date(2026, 5, 1, hour: 8, calendar: calendar)
    let transactionID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000101"))
    let subscription = detectedSubscription(
        renewalDate: renewalDate,
        transactionIDs: [transactionID]
    )

    let reminders = SubscriptionRenewalReminderPlanner.reminders(
        for: [subscription],
        referenceDate: referenceDate,
        calendar: calendar
    )

    let reminder = try #require(reminders.first)
    let expectedNotificationDate = try date(2026, 4, 28, hour: 8, calendar: calendar)
    #expect(reminders.count == 1)
    #expect(reminder.subscriptionID == subscription.id)
    #expect(reminder.renewalDate == renewalDate)
    #expect(reminder.notificationDate == expectedNotificationDate)
    #expect(reminder.dayCountUntilRenewal == 5)
    #expect(reminder.id == "subscription-renewal-00000000-0000-0000-0000-000000000101-20260501")
}

@Test("uses near-term fallback when preferred reminder date has passed")
func usesNearTermFallbackWhenPreferredReminderDateHasPassed() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 30, hour: 9, calendar: calendar)
    let renewalDate = try date(2026, 5, 1, hour: 8, calendar: calendar)
    let subscription = detectedSubscription(renewalDate: renewalDate)

    let reminders = SubscriptionRenewalReminderPlanner.reminders(
        for: [subscription],
        referenceDate: referenceDate,
        calendar: calendar
    )

    let reminder = try #require(reminders.first)
    let expectedNotificationDate = try date(2026, 4, 30, hour: 10, calendar: calendar)
    #expect(reminder.notificationDate == expectedNotificationDate)
    #expect(reminder.dayCountUntilRenewal == 1)
}

@Test("ignores renewals outside due soon window")
func ignoresRenewalsOutsideDueSoonWindow() throws {
    let calendar = Calendar(identifier: .gregorian)
    let referenceDate = try date(2026, 4, 20, hour: 9, calendar: calendar)
    let renewalDate = try date(2026, 5, 1, hour: 8, calendar: calendar)
    let subscription = detectedSubscription(renewalDate: renewalDate)

    let reminders = SubscriptionRenewalReminderPlanner.reminders(
        for: [subscription],
        referenceDate: referenceDate,
        calendar: calendar
    )

    #expect(reminders.isEmpty)
}

private func detectedSubscription(
    renewalDate: Date,
    transactionIDs: [Transaction.ID] = []
) -> DetectedSubscription {
    DetectedSubscription(
        merchant: SubscriptionMerchant(
            name: "Netflix",
            normalizedKey: "note:netflix",
            source: .note
        ),
        category: .entertainment,
        interval: .monthly,
        averageAmount: 260_000,
        monthlyAmount: 260_000,
        lastBillingDate: renewalDate.addingTimeInterval(-2_592_000),
        nextBillingDate: renewalDate,
        transactionIDs: transactionIDs,
        confidence: 1
    )
}

private func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    hour: Int,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
