import Testing
import ComposableArchitecture
import AppearanceDomain
@testable import AppearanceFeature

@MainActor
@Test("loads stored appearance")
func loadsStoredAppearance() async {
    let storedSettings = AppearanceSettings(
        mode: .dark,
        accentColor: .purple
    )
    let store = TestStore(initialState: AppearanceFeature.State()) {
        AppearanceFeature()
    } withDependencies: {
        $0.appearanceSettingsRepository.load = { storedSettings }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.settingsLoaded(storedSettings)) {
        $0.settings = storedSettings
        $0.isLoading = false
    }
}

@MainActor
@Test("saves selected appearance mode")
func savesSelectedAppearanceMode() async {
    let expectedSettings = AppearanceSettings(
        mode: .dark,
        accentColor: .mint
    )
    let store = TestStore(initialState: AppearanceFeature.State()) {
        AppearanceFeature()
    } withDependencies: {
        $0.appearanceSettingsRepository.save = { settings in
            #expect(settings == expectedSettings)
        }
    }

    await store.send(.modeSelected(.dark)) {
        $0.settings = expectedSettings
        $0.isSaving = true
    }
    await store.receive(.settingsSaved(expectedSettings)) {
        $0.isSaving = false
    }
}
