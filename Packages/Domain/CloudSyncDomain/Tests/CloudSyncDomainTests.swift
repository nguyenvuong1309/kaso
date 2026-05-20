import Foundation
import Testing
@testable import CloudSyncDomain

struct CloudSyncDomainTests {
    @Test("disabled status is not enabled")
    func disabledIsNotEnabled() {
        let status = CloudSyncStatus(
            availability: .available,
            state: .disabled
        )
        #expect(status.isEnabled == false)
        #expect(status.statusKey == "cloudSync.status.disabled")
    }

    @Test("idle with last sync date returns idle key")
    func idleWithDateKey() {
        let status = CloudSyncStatus(
            availability: .available,
            state: .idle(lastSyncedAt: Date())
        )
        #expect(status.isEnabled)
        #expect(status.statusKey == "cloudSync.status.idle")
    }

    @Test("idle without last sync returns never key")
    func idleWithoutDateKey() {
        let status = CloudSyncStatus(
            availability: .available,
            state: .idle(lastSyncedAt: nil)
        )
        #expect(status.statusKey == "cloudSync.status.idleNever")
    }

    @Test("failed state surfaces failed key")
    func failedKey() {
        let status = CloudSyncStatus(
            state: .failed(messageKey: "x", retryAfter: nil)
        )
        #expect(status.statusKey == "cloudSync.status.failed")
    }

    @Test("delta empty when both lists empty")
    func deltaEmpty() {
        #expect(CloudSyncDelta.empty.isEmpty)
        #expect(CloudSyncDelta(upserts: [], deletions: []).isEmpty)
        let record = CloudSyncRecord(
            id: UUID(),
            kind: .transaction,
            payload: Data(),
            modifiedAt: Date()
        )
        #expect(CloudSyncDelta(upserts: [record]).isEmpty == false)
    }

    @Test("default preferences sync all kinds and start disabled")
    func defaultPreferences() {
        let prefs = CloudSyncPreferences.default
        #expect(prefs.isEnabled == false)
        #expect(prefs.syncedKinds == Set(CloudSyncRecord.Kind.allCases))
        #expect(prefs.lastSyncedAt == nil)
    }

    @Test("empty client always reports unavailable and throws on upload")
    func emptyClient() async {
        let availability = await CloudSyncClient.empty.availability()
        #expect(availability == .unavailable)
        await #expect(throws: CloudSyncError.notAvailable) {
            try await CloudSyncClient.empty.upload(.empty)
        }
    }
}
