import Foundation
import Testing
@testable import RemindersDomain

struct ReminderPreferenceTests {
    // MARK: - ReminderPreference

    @Test("default initializer values")
    func defaultInit() {
        let preference = ReminderPreference(kind: .endOfDayEntry)
        #expect(preference.kind == .endOfDayEntry)
        #expect(preference.isEnabled == false)
        #expect(preference.hour == 21)
        #expect(preference.minute == 0)
    }

    @Test("id equals kind rawValue")
    func idMatchesKind() {
        for kind in ReminderKind.allCases {
            #expect(ReminderPreference(kind: kind).id == kind.rawValue)
        }
    }

    @Test("custom values are stored when within range")
    func customValues() {
        let preference = ReminderPreference(
            kind: .largeExpense,
            isEnabled: true,
            hour: 8,
            minute: 30
        )
        #expect(preference.isEnabled)
        #expect(preference.hour == 8)
        #expect(preference.minute == 30)
    }

    @Test("hour is clamped to lower bound 0")
    func hourClampLower() {
        let preference = ReminderPreference(kind: .endOfDayEntry, hour: -10)
        #expect(preference.hour == 0)
    }

    @Test("hour is clamped to upper bound 23")
    func hourClampUpper() {
        let preference = ReminderPreference(kind: .endOfDayEntry, hour: 24)
        #expect(preference.hour == 23)
    }

    @Test("minute is clamped to lower bound 0")
    func minuteClampLower() {
        let preference = ReminderPreference(kind: .endOfDayEntry, minute: -1)
        #expect(preference.minute == 0)
    }

    @Test("minute is clamped to upper bound 59")
    func minuteClampUpper() {
        let preference = ReminderPreference(kind: .endOfDayEntry, minute: 120)
        #expect(preference.minute == 59)
    }

    @Test("boundary hour and minute values pass through unchanged")
    func boundaryValues() {
        let low = ReminderPreference(kind: .endOfDayEntry, hour: 0, minute: 0)
        #expect(low.hour == 0)
        #expect(low.minute == 0)
        let high = ReminderPreference(kind: .endOfDayEntry, hour: 23, minute: 59)
        #expect(high.hour == 23)
        #expect(high.minute == 59)
    }

    @Test("equatable distinguishes differing fields")
    func equatable() {
        let base = ReminderPreference(kind: .endOfDayEntry, isEnabled: true, hour: 9, minute: 15)
        #expect(base == ReminderPreference(kind: .endOfDayEntry, isEnabled: true, hour: 9, minute: 15))
        #expect(base != ReminderPreference(kind: .endOfDayEntry, isEnabled: false, hour: 9, minute: 15))
        #expect(base != ReminderPreference(kind: .endOfDayEntry, isEnabled: true, hour: 10, minute: 15))
        #expect(base != ReminderPreference(kind: .endOfDayEntry, isEnabled: true, hour: 9, minute: 16))
        #expect(base != ReminderPreference(kind: .largeExpense, isEnabled: true, hour: 9, minute: 15))
    }

    // MARK: - ReminderConfiguration

    @Test("default uses hour 20 for no-spend streak and 21 otherwise")
    func defaultHours() {
        let config = ReminderConfiguration.default
        #expect(config.preference(for: .noSpendStreak).hour == 20)
        for kind in ReminderKind.allCases where kind != .noSpendStreak {
            #expect(config.preference(for: kind).hour == 21)
        }
        #expect(config.preferences.allSatisfy { $0.minute == 0 })
    }

    @Test("preference returns a synthesized default when kind is absent")
    func preferenceMissing() {
        let config = ReminderConfiguration(preferences: [])
        let preference = config.preference(for: .budgetNearLimit)
        #expect(preference.kind == .budgetNearLimit)
        #expect(preference.isEnabled == false)
        #expect(preference.hour == 21)
        #expect(preference.minute == 0)
    }

    @Test("update appends preference when kind is absent")
    func updateAppends() {
        var config = ReminderConfiguration(preferences: [])
        let preference = ReminderPreference(kind: .largeExpense, isEnabled: true, hour: 7, minute: 5)
        config.update(preference)
        #expect(config.preferences.count == 1)
        #expect(config.preference(for: .largeExpense) == preference)
    }

    @Test("update mutates only the matching preference and preserves count")
    func updatePreservesOthers() {
        var config = ReminderConfiguration.default
        let countBefore = config.preferences.count
        var preference = config.preference(for: .budgetNearLimit)
        preference.isEnabled = true
        preference.minute = 45
        config.update(preference)
        #expect(config.preferences.count == countBefore)
        #expect(config.preference(for: .budgetNearLimit).isEnabled)
        #expect(config.preference(for: .budgetNearLimit).minute == 45)
        #expect(config.preference(for: .endOfDayEntry).isEnabled == false)
    }

    @Test("configuration is equatable")
    func configurationEquatable() {
        let a = ReminderConfiguration(preferences: [ReminderPreference(kind: .endOfDayEntry)])
        let b = ReminderConfiguration(preferences: [ReminderPreference(kind: .endOfDayEntry)])
        let c = ReminderConfiguration(preferences: [ReminderPreference(kind: .largeExpense)])
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - ReminderRepository

    @Test("empty repository load returns the default configuration")
    func repositoryEmptyLoad() async throws {
        let config = try await ReminderRepository.empty.load()
        #expect(config == .default)
    }

    @Test("empty repository save is a no-op that does not throw")
    func repositoryEmptySave() async throws {
        try await ReminderRepository.empty.save(.default)
    }

    // MARK: - ReminderScheduler

    @Test("empty scheduler reports not-determined authorization")
    func schedulerEmptyAuthorization() async {
        let status = await ReminderScheduler.empty.authorizationStatus()
        #expect(status == .notDetermined)
    }

    @Test("empty scheduler denies authorization requests")
    func schedulerEmptyRequest() async {
        let granted = await ReminderScheduler.empty.requestAuthorization()
        #expect(granted == false)
    }

    @Test("empty scheduler apply is a no-op")
    func schedulerEmptyApply() async {
        await ReminderScheduler.empty.apply(.default)
    }

    // MARK: - ReminderAuthorizationStatus

    @Test("authorization status values are distinct")
    func authorizationStatusEquatable() {
        let all: [ReminderAuthorizationStatus] = [.notDetermined, .denied, .authorized, .provisional]
        for (offset, lhs) in all.enumerated() {
            for (innerOffset, rhs) in all.enumerated() {
                if offset == innerOffset {
                    #expect(lhs == rhs)
                } else {
                    #expect(lhs != rhs)
                }
            }
        }
    }
}
