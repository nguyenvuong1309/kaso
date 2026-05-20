import Foundation

public enum CloudSyncError: Error, Equatable, Sendable {
    case notAvailable
    case authenticationRequired
    case quotaExceeded
    case networkFailure
    case unknown
}

/// Adapter to whatever cloud database the app uses (CloudKit by default).
/// The domain layer never imports `CloudKit`; the live client wires it up in
/// the App target.
public struct CloudSyncClient: Sendable {
    public typealias Availability = @Sendable () async -> CloudSyncAvailability
    public typealias FetchChanges = @Sendable (_ since: Date?) async throws -> CloudSyncDelta
    public typealias Upload = @Sendable (_ delta: CloudSyncDelta) async throws -> Void

    public var availability: Availability
    public var fetchChanges: FetchChanges
    public var upload: Upload

    public init(
        availability: @escaping Availability,
        fetchChanges: @escaping FetchChanges,
        upload: @escaping Upload
    ) {
        self.availability = availability
        self.fetchChanges = fetchChanges
        self.upload = upload
    }
}

public extension CloudSyncClient {
    static let empty = CloudSyncClient(
        availability: { .unavailable },
        fetchChanges: { _ in .empty },
        upload: { _ in throw CloudSyncError.notAvailable }
    )

    static let preview = CloudSyncClient(
        availability: { .available },
        fetchChanges: { _ in .empty },
        upload: { _ in }
    )
}
