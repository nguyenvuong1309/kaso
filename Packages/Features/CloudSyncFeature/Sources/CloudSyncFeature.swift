import CloudSyncDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct CloudSyncFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var preferences: CloudSyncPreferences
        public var status: CloudSyncStatus
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            preferences: CloudSyncPreferences = .default,
            status: CloudSyncStatus = CloudSyncStatus(),
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.preferences = preferences
            self.status = status
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case preferencesLoaded(CloudSyncPreferences)
        case availabilityResolved(CloudSyncAvailability)
        case loadFailed(String)
        case toggleEnabled(Bool)
        case preferencesSaved(CloudSyncPreferences)
        case syncNowButtonTapped
        case syncStarted
        case syncCompleted(uploaded: Int, downloaded: Int, finishedAt: Date)
        case syncFailed(String)
    }

    @Dependency(\.cloudSyncClient) private var client
    @Dependency(\.cloudSyncPreferencesRepository) private var preferencesRepository
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let prefs = try await preferencesRepository.load()
                        await send(.preferencesLoaded(prefs))
                        let availability = await client.availability()
                        await send(.availabilityResolved(availability))
                    } catch {
                        await send(.loadFailed("cloudSync.error.loadFailed"))
                    }
                }

            case let .preferencesLoaded(prefs):
                state.preferences = prefs
                state.status.state = prefs.isEnabled
                    ? .idle(lastSyncedAt: prefs.lastSyncedAt)
                    : .disabled
                return .none

            case let .availabilityResolved(availability):
                state.isLoading = false
                state.status.availability = availability
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case let .toggleEnabled(isOn):
                guard state.status.availability == .available else {
                    state.errorMessageKey = "cloudSync.error.unavailable"
                    return .none
                }
                state.preferences.isEnabled = isOn
                state.status.state = isOn
                    ? .idle(lastSyncedAt: state.preferences.lastSyncedAt)
                    : .disabled
                let updated = state.preferences
                return .run { send in
                    try? await preferencesRepository.save(updated)
                    await send(.preferencesSaved(updated))
                }

            case let .preferencesSaved(prefs):
                state.preferences = prefs
                return .none

            case .syncNowButtonTapped:
                guard state.preferences.isEnabled else { return .none }
                guard state.status.availability == .available else {
                    state.errorMessageKey = "cloudSync.error.unavailable"
                    return .none
                }
                if case .syncing = state.status.state { return .none }
                return .send(.syncStarted)

            case .syncStarted:
                state.status.state = .syncing(progress: 0)
                state.errorMessageKey = nil
                return .run { [since = state.preferences.lastSyncedAt] send in
                    do {
                        let delta = try await client.fetchChanges(since)
                        try await client.upload(.empty)
                        await send(.syncCompleted(
                            uploaded: 0,
                            downloaded: delta.upserts.count,
                            finishedAt: Date()
                        ))
                    } catch {
                        await send(.syncFailed("cloudSync.error.syncFailed"))
                    }
                }

            case let .syncCompleted(uploaded, downloaded, finishedAt):
                state.status.recordsUploaded += uploaded
                state.status.recordsDownloaded += downloaded
                state.status.state = .idle(lastSyncedAt: finishedAt)
                state.preferences.lastSyncedAt = finishedAt
                let updated = state.preferences
                return .run { _ in
                    try? await preferencesRepository.save(updated)
                }

            case let .syncFailed(key):
                state.status.state = .failed(messageKey: key, retryAfter: nil)
                state.errorMessageKey = key
                return .none
            }
        }
    }
}
