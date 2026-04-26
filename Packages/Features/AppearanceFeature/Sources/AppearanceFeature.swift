import AppearanceDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct AppearanceFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var settings: AppearanceSettings
        public var isSettingsPresented: Bool
        public var isLoading: Bool
        public var isSaving: Bool
        public var errorMessageKey: String?

        public init(
            settings: AppearanceSettings = .defaultValue,
            isSettingsPresented: Bool = false,
            isLoading: Bool = false,
            isSaving: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.settings = settings
            self.isSettingsPresented = isSettingsPresented
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case settingsLoaded(AppearanceSettings)
        case loadFailed(String)
        case settingsButtonTapped
        case settingsDismissed
        case modeSelected(AppearanceMode)
        case accentColorSelected(AccentColorOption)
        case settingsSaved(AppearanceSettings)
        case saveFailed(String, AppearanceSettings)
    }

    @Dependency(\.appearanceSettingsRepository) private var repository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let settings = try await repository.load()
                        await send(.settingsLoaded(settings))
                    } catch {
                        await send(.loadFailed("appearance.error.loadFailed"))
                    }
                }

            case let .settingsLoaded(settings):
                state.settings = settings
                state.isLoading = false
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .settingsButtonTapped:
                state.isSettingsPresented = true
                state.errorMessageKey = nil
                return .none

            case .settingsDismissed:
                state.isSettingsPresented = false
                return .none

            case let .modeSelected(mode):
                guard state.settings.mode != mode else {
                    return .none
                }

                let previousSettings = state.settings
                state.settings.mode = mode
                state.isSaving = true
                state.errorMessageKey = nil
                return save(
                    settings: state.settings,
                    previousSettings: previousSettings,
                    failureMessageKey: "appearance.error.saveFailed"
                )

            case let .accentColorSelected(accentColor):
                guard state.settings.accentColor != accentColor else {
                    return .none
                }

                let previousSettings = state.settings
                state.settings.accentColor = accentColor
                state.isSaving = true
                state.errorMessageKey = nil
                return save(
                    settings: state.settings,
                    previousSettings: previousSettings,
                    failureMessageKey: "appearance.error.saveFailed"
                )

            case let .settingsSaved(settings):
                state.settings = settings
                state.isSaving = false
                state.errorMessageKey = nil
                return .none

            case let .saveFailed(messageKey, previousSettings):
                state.settings = previousSettings
                state.isSaving = false
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func save(
        settings: AppearanceSettings,
        previousSettings: AppearanceSettings,
        failureMessageKey: String
    ) -> Effect<Action> {
        .run { send in
            do {
                try await repository.save(settings)
                await send(.settingsSaved(settings))
            } catch {
                await send(.saveFailed(failureMessageKey, previousSettings))
            }
        }
    }
}
