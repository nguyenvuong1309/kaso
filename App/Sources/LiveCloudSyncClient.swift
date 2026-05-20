import CloudKit
import CloudSyncDomain
import Foundation

/// Wires `CloudSyncDomain.CloudSyncClient` to CloudKit's private database.
///
/// Each `CloudSyncRecord` becomes one `CKRecord` whose payload is the
/// already-encrypted blob produced by the local encrypted stores. The cloud
/// only ever holds ciphertext, so even Apple cannot read the user's data.
enum LiveCloudSyncClient {
    static let containerID = "iCloud.com.vuongnguyen.kaso"

    static func make() -> CloudSyncClient {
        CloudSyncClient(
            availability: {
                do {
                    let status = try await CKContainer(identifier: containerID).accountStatus()
                    switch status {
                    case .available: return .available
                    case .noAccount, .couldNotDetermine: return .unavailable
                    case .restricted: return .restricted
                    case .temporarilyUnavailable: return .temporarilyUnavailable
                    @unknown default: return .unavailable
                    }
                } catch {
                    return .unavailable
                }
            },
            fetchChanges: { since in
                try await fetchChanges(since: since)
            },
            upload: { delta in
                try await upload(delta: delta)
            }
        )
    }

    private static let recordType = "EncryptedRecord"

    private static func privateDatabase() -> CKDatabase {
        CKContainer(identifier: containerID).privateCloudDatabase
    }

    private static func fetchChanges(since: Date?) async throws -> CloudSyncDelta {
        let predicate: NSPredicate
        if let since {
            predicate = NSPredicate(format: "modificationDate > %@", since as NSDate)
        } else {
            predicate = NSPredicate(value: true)
        }
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        do {
            let (matchResults, _) = try await privateDatabase().records(matching: query, resultsLimit: 200)
            var upserts: [CloudSyncRecord] = []
            for (_, result) in matchResults {
                guard
                    case let .success(record) = result,
                    let payload = record["payload"] as? Data,
                    let kindRaw = record["kind"] as? String,
                    let kind = CloudSyncRecord.Kind(rawValue: kindRaw),
                    let idString = record["recordID"] as? String,
                    let recordID = UUID(uuidString: idString)
                else { continue }
                let modifiedAt = record.modificationDate ?? Date()
                let version = (record["version"] as? Int) ?? 1
                upserts.append(
                    CloudSyncRecord(
                        id: recordID,
                        kind: kind,
                        payload: payload,
                        modifiedAt: modifiedAt,
                        version: version
                    )
                )
            }
            return CloudSyncDelta(upserts: upserts, deletions: [])
        } catch let error as CKError {
            throw map(error)
        }
    }

    private static func upload(delta: CloudSyncDelta) async throws {
        let database = privateDatabase()
        let upsertRecords = delta.upserts.map { record -> CKRecord in
            let ckRecord = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: record.id.uuidString))
            ckRecord["payload"] = record.payload as CKRecordValue
            ckRecord["kind"] = record.kind.rawValue as CKRecordValue
            ckRecord["recordID"] = record.id.uuidString as CKRecordValue
            ckRecord["version"] = record.version as CKRecordValue
            return ckRecord
        }
        let deletionIDs = delta.deletions.map { CKRecord.ID(recordName: $0.uuidString) }
        guard upsertRecords.isEmpty == false || deletionIDs.isEmpty == false else { return }
        let operation = CKModifyRecordsOperation(
            recordsToSave: upsertRecords,
            recordIDsToDelete: deletionIDs
        )
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success: continuation.resume(returning: ())
                case let .failure(error):
                    if let ckError = error as? CKError {
                        continuation.resume(throwing: map(ckError))
                    } else {
                        continuation.resume(throwing: CloudSyncError.unknown)
                    }
                }
            }
            database.add(operation)
        }
    }

    private static func map(_ ckError: CKError) -> CloudSyncError {
        switch ckError.code {
        case .quotaExceeded: .quotaExceeded
        case .notAuthenticated: .authenticationRequired
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited: .networkFailure
        default: .unknown
        }
    }
}
