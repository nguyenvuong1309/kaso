import Foundation

/// One unit of synced data: an opaque encrypted blob keyed by the local
/// record's UUID. The cloud never sees plaintext — it stores AES-GCM
/// sealed boxes that only decrypt with the user's local symmetric key.
public struct CloudSyncRecord: Identifiable, Equatable, Sendable {
    public enum Kind: String, Codable, Equatable, Sendable, CaseIterable {
        case transaction
        case budget
        case category
        case savingGoal
    }

    public let id: UUID
    public let kind: Kind
    public let payload: Data           // AES-GCM sealed box
    public let modifiedAt: Date
    public let version: Int

    public init(
        id: UUID,
        kind: Kind,
        payload: Data,
        modifiedAt: Date,
        version: Int = 1
    ) {
        self.id = id
        self.kind = kind
        self.payload = payload
        self.modifiedAt = modifiedAt
        self.version = version
    }
}

public struct CloudSyncDelta: Equatable, Sendable {
    public let upserts: [CloudSyncRecord]
    public let deletions: [UUID]

    public init(upserts: [CloudSyncRecord] = [], deletions: [UUID] = []) {
        self.upserts = upserts
        self.deletions = deletions
    }

    public static let empty = CloudSyncDelta()

    public var isEmpty: Bool {
        upserts.isEmpty && deletions.isEmpty
    }
}
