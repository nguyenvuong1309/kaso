import CloudSyncDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import CloudSyncFeature

@MainActor
struct CloudSyncFeatureTests {
    @Test("task loads preferences and availability")
    func taskLoads() async {
        let prefs = CloudSyncPreferences(isEnabled: true, lastSyncedAt: Date(timeIntervalSince1970: 1_000))
        let store = TestStore(initialState: CloudSyncFeature.State()) {
            CloudSyncFeature()
        } withDependencies: {
            $0.cloudSyncClient = CloudSyncClient(
                availability: { .available },
                fetchChanges: { _ in .empty },
                upload: { _ in }
            )
            $0.cloudSyncPreferencesRepository = CloudSyncPreferencesRepository(
                load: { prefs },
                save: { _ in }
            )
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessageKey = nil
        }
        await store.receive(.preferencesLoaded(prefs)) {
            $0.preferences = prefs
            $0.status.state = .idle(lastSyncedAt: prefs.lastSyncedAt)
        }
        await store.receive(.availabilityResolved(.available)) {
            $0.isLoading = false
            $0.status.availability = .available
        }
    }

    @Test("toggle fails when iCloud unavailable")
    func toggleFailsWhenUnavailable() async {
        let store = TestStore(initialState: CloudSyncFeature.State(
            status: CloudSyncStatus(availability: .unavailable)
        )) {
            CloudSyncFeature()
        } withDependencies: {
            $0.cloudSyncClient = .empty
            $0.cloudSyncPreferencesRepository = .empty
        }

        await store.send(.toggleEnabled(true)) {
            $0.errorMessageKey = "cloudSync.error.unavailable"
        }
    }

    @Test("toggle enabled persists preferences and updates state")
    func toggleEnabledPersists() async {
        let store = TestStore(initialState: CloudSyncFeature.State(
            status: CloudSyncStatus(availability: .available, state: .disabled)
        )) {
            CloudSyncFeature()
        } withDependencies: {
            $0.cloudSyncClient = .preview
            $0.cloudSyncPreferencesRepository = .empty
        }

        await store.send(.toggleEnabled(true)) {
            $0.preferences.isEnabled = true
            $0.status.state = .idle(lastSyncedAt: nil)
        }
        let expected = CloudSyncPreferences(isEnabled: true)
        await store.receive(.preferencesSaved(expected))
    }

    @Test("syncFailed marks state as failed and records error message")
    func syncFailedMarksState() async {
        let store = TestStore(initialState: CloudSyncFeature.State(
            status: CloudSyncStatus(
                availability: .available,
                state: .syncing(progress: 0)
            )
        )) {
            CloudSyncFeature()
        } withDependencies: {
            $0.cloudSyncClient = .empty
            $0.cloudSyncPreferencesRepository = .empty
        }

        await store.send(.syncFailed("cloudSync.error.syncFailed")) {
            $0.status.state = .failed(messageKey: "cloudSync.error.syncFailed", retryAfter: nil)
            $0.errorMessageKey = "cloudSync.error.syncFailed"
        }
    }
}
