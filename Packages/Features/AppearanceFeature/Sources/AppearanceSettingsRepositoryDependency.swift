import AppearanceDomain
import ComposableArchitecture

private enum AppearanceSettingsRepositoryKey: DependencyKey {
    static let liveValue = AppearanceSettingsRepository.empty
    static let previewValue = AppearanceSettingsRepository.preview
    static let testValue = AppearanceSettingsRepository.empty
}

public extension AppearanceSettingsRepository {
    static let preview = AppearanceSettingsRepository(
        load: {
            AppearanceSettings(
                mode: .system,
                accentColor: .mint
            )
        },
        save: { _ in }
    )
}

public extension DependencyValues {
    var appearanceSettingsRepository: AppearanceSettingsRepository {
        get { self[AppearanceSettingsRepositoryKey.self] }
        set { self[AppearanceSettingsRepositoryKey.self] = newValue }
    }
}
