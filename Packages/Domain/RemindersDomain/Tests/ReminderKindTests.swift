import Foundation
import Testing
@testable import RemindersDomain

struct ReminderKindTests {
    @Test("allCases contains exactly the five expected kinds")
    func allCasesContent() {
        #expect(ReminderKind.allCases == [
            .endOfDayEntry,
            .budgetNearLimit,
            .subscriptionRenewal,
            .noSpendStreak,
            .largeExpense,
        ])
        #expect(ReminderKind.allCases.count == 5)
    }

    @Test("id equals rawValue for every kind")
    func idMatchesRawValue() {
        for kind in ReminderKind.allCases {
            #expect(kind.id == kind.rawValue)
        }
    }

    @Test("rawValue strings are stable")
    func rawValues() {
        #expect(ReminderKind.endOfDayEntry.rawValue == "endOfDayEntry")
        #expect(ReminderKind.budgetNearLimit.rawValue == "budgetNearLimit")
        #expect(ReminderKind.subscriptionRenewal.rawValue == "subscriptionRenewal")
        #expect(ReminderKind.noSpendStreak.rawValue == "noSpendStreak")
        #expect(ReminderKind.largeExpense.rawValue == "largeExpense")
    }

    @Test("init from rawValue round-trips")
    func rawValueRoundTrip() {
        for kind in ReminderKind.allCases {
            #expect(ReminderKind(rawValue: kind.rawValue) == kind)
        }
    }

    @Test("init from unknown rawValue returns nil")
    func rawValueUnknown() {
        #expect(ReminderKind(rawValue: "unknown") == nil)
    }

    @Test("localization keys are derived from rawValue")
    func localizationKeys() {
        for kind in ReminderKind.allCases {
            #expect(kind.titleKey == "reminders.kind.\(kind.rawValue).title")
            #expect(kind.descriptionKey == "reminders.kind.\(kind.rawValue).description")
            #expect(kind.notificationTitleKey == "reminders.kind.\(kind.rawValue).notification.title")
            #expect(kind.notificationBodyKey == "reminders.kind.\(kind.rawValue).notification.body")
        }
    }

    @Test("specific localization keys for end-of-day entry")
    func specificKeys() {
        let kind = ReminderKind.endOfDayEntry
        #expect(kind.titleKey == "reminders.kind.endOfDayEntry.title")
        #expect(kind.descriptionKey == "reminders.kind.endOfDayEntry.description")
        #expect(kind.notificationTitleKey == "reminders.kind.endOfDayEntry.notification.title")
        #expect(kind.notificationBodyKey == "reminders.kind.endOfDayEntry.notification.body")
    }

    @Test("icon system name maps each kind to its symbol")
    func iconSystemNames() {
        #expect(ReminderKind.endOfDayEntry.iconSystemName == "moon.stars")
        #expect(ReminderKind.budgetNearLimit.iconSystemName == "exclamationmark.gauge")
        #expect(ReminderKind.subscriptionRenewal.iconSystemName == "calendar.badge.clock")
        #expect(ReminderKind.noSpendStreak.iconSystemName == "flame")
        #expect(ReminderKind.largeExpense.iconSystemName == "bell.badge")
    }

    @Test("every icon system name is non-empty and unique")
    func iconSystemNamesUnique() {
        let icons = ReminderKind.allCases.map(\.iconSystemName)
        #expect(icons.allSatisfy { !$0.isEmpty })
        #expect(Set(icons).count == icons.count)
    }

    @Test("isDailySchedule is true only for end-of-day entry and no-spend streak")
    func dailySchedule() {
        #expect(ReminderKind.endOfDayEntry.isDailySchedule)
        #expect(ReminderKind.noSpendStreak.isDailySchedule)
        #expect(!ReminderKind.budgetNearLimit.isDailySchedule)
        #expect(!ReminderKind.subscriptionRenewal.isDailySchedule)
        #expect(!ReminderKind.largeExpense.isDailySchedule)
    }

    @Test("exactly two kinds use a daily schedule")
    func dailyScheduleCount() {
        let daily = ReminderKind.allCases.filter(\.isDailySchedule)
        #expect(daily.count == 2)
        #expect(Set(daily) == [.endOfDayEntry, .noSpendStreak])
    }
}
