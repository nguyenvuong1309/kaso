import ComposableArchitecture
import Foundation
import RemindersDomain
import Testing
@testable import RemindersFeature

@MainActor
struct RemindersFeatureTests {
    @Test("toggling a kind persists and applies configuration")
    func toggleSavesAndApplies() async {
        let saved = LockIsolated<ReminderConfiguration?>(nil)
        let applied = LockIsolated<ReminderConfiguration?>(nil)

        let store = TestStore(initialState: RemindersFeature.State()) {
            RemindersFeature()
        } withDependencies: {
            $0.reminderRepository = ReminderRepository(
                load: { .default },
                save: { config in saved.setValue(config) }
            )
            $0.reminderScheduler = ReminderScheduler(
                authorizationStatus: { .authorized },
                requestAuthorization: { true },
                apply: { config in applied.setValue(config) }
            )
        }

        await store.send(.enabledToggled(kind: .endOfDayEntry, isOn: true)) {
            var config = $0.configuration
            var preference = config.preference(for: .endOfDayEntry)
            preference.isEnabled = true
            config.update(preference)
            $0.configuration = config
        }

        await store.receive(\.configurationApplied)

        #expect(saved.value?.preference(for: .endOfDayEntry).isEnabled == true)
        #expect(applied.value?.preference(for: .endOfDayEntry).isEnabled == true)
    }
}
