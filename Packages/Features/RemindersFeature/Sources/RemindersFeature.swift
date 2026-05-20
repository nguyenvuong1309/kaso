import ComposableArchitecture
import Foundation
import RemindersDomain

@Reducer
public struct RemindersFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var configuration: ReminderConfiguration
        public var authorizationStatus: ReminderAuthorizationStatus
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            configuration: ReminderConfiguration = .default,
            authorizationStatus: ReminderAuthorizationStatus = .notDetermined,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.configuration = configuration
            self.authorizationStatus = authorizationStatus
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case configurationLoaded(ReminderConfiguration)
        case authorizationStatusLoaded(ReminderAuthorizationStatus)
        case loadFailed(String)
        case enabledToggled(kind: ReminderKind, isOn: Bool)
        case timeChanged(kind: ReminderKind, hour: Int, minute: Int)
        case authorizationRequested
        case authorizationResolved(Bool)
        case configurationApplied
        case saveFailed(String)
    }

    @Dependency(\.reminderRepository) private var repository
    @Dependency(\.reminderScheduler) private var scheduler

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let config = try await repository.load()
                        await send(.configurationLoaded(config))
                        let status = await scheduler.authorizationStatus()
                        await send(.authorizationStatusLoaded(status))
                    } catch {
                        await send(.loadFailed("reminders.error.loadFailed"))
                    }
                }

            case let .configurationLoaded(config):
                state.isLoading = false
                state.configuration = config
                return .none

            case let .authorizationStatusLoaded(status):
                state.authorizationStatus = status
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .enabledToggled(kind, isOn):
                var preference = state.configuration.preference(for: kind)
                preference.isEnabled = isOn
                state.configuration.update(preference)
                let config = state.configuration
                return .run { send in
                    do {
                        try await repository.save(config)
                        await scheduler.apply(config)
                        await send(.configurationApplied)
                    } catch {
                        await send(.saveFailed("reminders.error.saveFailed"))
                    }
                }

            case let .timeChanged(kind, hour, minute):
                var preference = state.configuration.preference(for: kind)
                preference.hour = hour
                preference.minute = minute
                state.configuration.update(preference)
                let config = state.configuration
                return .run { send in
                    do {
                        try await repository.save(config)
                        await scheduler.apply(config)
                        await send(.configurationApplied)
                    } catch {
                        await send(.saveFailed("reminders.error.saveFailed"))
                    }
                }

            case .authorizationRequested:
                return .run { send in
                    let granted = await scheduler.requestAuthorization()
                    await send(.authorizationResolved(granted))
                    let status = await scheduler.authorizationStatus()
                    await send(.authorizationStatusLoaded(status))
                }

            case let .authorizationResolved(granted):
                if granted == false {
                    state.errorMessageKey = "reminders.error.permissionDenied"
                }
                return .none

            case .configurationApplied:
                state.errorMessageKey = nil
                return .none

            case let .saveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}
