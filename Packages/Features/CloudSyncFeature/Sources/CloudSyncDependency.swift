import CloudSyncDomain
import ComposableArchitecture

private enum CloudSyncClientKey: DependencyKey {
    static let liveValue = CloudSyncClient.empty
    static let previewValue = CloudSyncClient.preview
    static let testValue = CloudSyncClient.empty
}

private enum CloudSyncPreferencesRepositoryKey: DependencyKey {
    static let liveValue = CloudSyncPreferencesRepository.empty
    static let previewValue = CloudSyncPreferencesRepository.preview
    static let testValue = CloudSyncPreferencesRepository.empty
}

public extension DependencyValues {
    var cloudSyncClient: CloudSyncClient {
        get { self[CloudSyncClientKey.self] }
        set { self[CloudSyncClientKey.self] = newValue }
    }

    var cloudSyncPreferencesRepository: CloudSyncPreferencesRepository {
        get { self[CloudSyncPreferencesRepositoryKey.self] }
        set { self[CloudSyncPreferencesRepositoryKey.self] = newValue }
    }
}
