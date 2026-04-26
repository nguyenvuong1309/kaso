import Foundation
import Testing
import AppearanceDomain
@testable import PersistenceKit

@Test("persists appearance settings in user defaults")
func persistsAppearanceSettingsInUserDefaults() async throws {
    let suiteName = "kaso.appearance.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)

    let repository = UserDefaultsAppearanceSettingsStore(suiteName: suiteName).repository()
    let settings = AppearanceSettings(
        mode: .dark,
        accentColor: .purple
    )

    try await repository.save(settings)

    let loadedSettings = try await repository.load()
    #expect(loadedSettings == settings)
}
