import Foundation

public enum CloudSyncAvailability: String, Codable, Equatable, Sendable {
    case unavailable      // No iCloud account / restricted
    case available         // Signed in and reachable
    case restricted        // Parental controls or MDM
    case temporarilyUnavailable
}

public enum CloudSyncState: Equatable, Sendable {
    case disabled
    case idle(lastSyncedAt: Date?)
    case syncing(progress: Double)
    case failed(messageKey: String, retryAfter: Date?)
}

public struct CloudSyncStatus: Equatable, Sendable {
    public var availability: CloudSyncAvailability
    public var state: CloudSyncState
    public var recordsUploaded: Int
    public var recordsDownloaded: Int

    public init(
        availability: CloudSyncAvailability = .unavailable,
        state: CloudSyncState = .disabled,
        recordsUploaded: Int = 0,
        recordsDownloaded: Int = 0
    ) {
        self.availability = availability
        self.state = state
        self.recordsUploaded = recordsUploaded
        self.recordsDownloaded = recordsDownloaded
    }

    public var isEnabled: Bool {
        if case .disabled = state { return false }
        return true
    }

    public var statusKey: String {
        switch state {
        case .disabled:
            "cloudSync.status.disabled"
        case let .idle(date):
            date == nil ? "cloudSync.status.idleNever" : "cloudSync.status.idle"
        case .syncing:
            "cloudSync.status.syncing"
        case .failed:
            "cloudSync.status.failed"
        }
    }
}
