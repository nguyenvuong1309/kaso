import Foundation
import Testing
@testable import RemindersDomain

struct RemindersDomainTests {
    @Test("default configuration includes every reminder kind")
    func defaultCoversAllKinds() {
        let config = ReminderConfiguration.default
        let kinds = Set(config.preferences.map(\.kind))
        #expect(kinds == Set(ReminderKind.allCases))
        #expect(config.preferences.allSatisfy { $0.isEnabled == false })
    }

    @Test("update replaces matching preference")
    func updateReplaces() {
        var config = ReminderConfiguration.default
        var preference = config.preference(for: .endOfDayEntry)
        preference.isEnabled = true
        preference.hour = 22
        config.update(preference)
        #expect(config.preference(for: .endOfDayEntry).isEnabled)
        #expect(config.preference(for: .endOfDayEntry).hour == 22)
    }

    @Test("preference clamps hour and minute")
    func preferenceClamps() {
        let preference = ReminderPreference(
            kind: .budgetNearLimit,
            hour: 99,
            minute: -5
        )
        #expect(preference.hour == 23)
        #expect(preference.minute == 0)
    }
}
