import Foundation
import Testing
@testable import CloudSyncDomain

struct CloudSyncStatusTests {
    // MARK: - Default init

    @Test("default status is unavailable, disabled, zero counts")
    func defaultInit() {
        let status = CloudSyncStatus()
        #expect(status.availability == .unavailable)
        #expect(status.state == .disabled)
        #expect(status.recordsUploaded == 0)
        #expect(status.recordsDownloaded == 0)
    }

    @Test("custom init keeps all provided values")
    func customInit() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let status = CloudSyncStatus(
            availability: .available,
            state: .idle(lastSyncedAt: date),
            recordsUploaded: 12,
            recordsDownloaded: 7
        )
        #expect(status.availability == .available)
        #expect(status.state == .idle(lastSyncedAt: date))
        #expect(status.recordsUploaded == 12)
        #expect(status.recordsDownloaded == 7)
    }

    // MARK: - isEnabled

    @Test("isEnabled is false only when state is disabled")
    func isEnabledDisabled() {
        let status = CloudSyncStatus(availability: .available, state: .disabled)
        #expect(status.isEnabled == false)
    }

    @Test("isEnabled is true for idle state")
    func isEnabledIdle() {
        let status = CloudSyncStatus(state: .idle(lastSyncedAt: nil))
        #expect(status.isEnabled)
    }

    @Test("isEnabled is true for syncing state")
    func isEnabledSyncing() {
        let status = CloudSyncStatus(state: .syncing(progress: 0.5))
        #expect(status.isEnabled)
    }

    @Test("isEnabled is true for failed state")
    func isEnabledFailed() {
        let status = CloudSyncStatus(state: .failed(messageKey: "k", retryAfter: nil))
        #expect(status.isEnabled)
    }

    // MARK: - statusKey

    @Test("statusKey maps syncing to syncing key")
    func statusKeySyncing() {
        let status = CloudSyncStatus(state: .syncing(progress: 0.25))
        #expect(status.statusKey == "cloudSync.status.syncing")
    }

    @Test("statusKey maps idle with date to idle and nil to idleNever")
    func statusKeyIdleVariants() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try makeDate(year: 2025, month: 1, day: 1, calendar: calendar)
        let withDate = CloudSyncStatus(state: .idle(lastSyncedAt: date))
        let never = CloudSyncStatus(state: .idle(lastSyncedAt: nil))
        #expect(withDate.statusKey == "cloudSync.status.idle")
        #expect(never.statusKey == "cloudSync.status.idleNever")
    }

    @Test("statusKey maps failed with retry date to failed key")
    func statusKeyFailedWithRetry() throws {
        let calendar = Calendar(identifier: .gregorian)
        let retry = try makeDate(year: 2026, month: 6, day: 17, calendar: calendar)
        let status = CloudSyncStatus(
            state: .failed(messageKey: "cloudSync.error.network", retryAfter: retry)
        )
        #expect(status.statusKey == "cloudSync.status.failed")
    }

    // MARK: - Equatable

    @Test("two statuses with identical fields are equal")
    func equatableEqual() {
        let a = CloudSyncStatus(availability: .available, state: .syncing(progress: 0.5), recordsUploaded: 3)
        let b = CloudSyncStatus(availability: .available, state: .syncing(progress: 0.5), recordsUploaded: 3)
        #expect(a == b)
    }

    @Test("statuses differing in counts are not equal")
    func equatableCounts() {
        let a = CloudSyncStatus(recordsUploaded: 1)
        let b = CloudSyncStatus(recordsUploaded: 2)
        #expect(a != b)
    }

    @Test("syncing states with different progress are not equal")
    func equatableSyncingProgress() {
        let a = CloudSyncState.syncing(progress: 0.1)
        let b = CloudSyncState.syncing(progress: 0.9)
        #expect(a != b)
    }

    // MARK: - CloudSyncAvailability

    @Test("availability round-trips through Codable for every case")
    func availabilityCodableRoundTrip() throws {
        let cases: [CloudSyncAvailability] = [
            .unavailable, .available, .restricted, .temporarilyUnavailable,
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for value in cases {
            let data = try encoder.encode(value)
            let decoded = try decoder.decode(CloudSyncAvailability.self, from: data)
            #expect(decoded == value)
        }
    }

    @Test("availability raw values are stable strings")
    func availabilityRawValues() {
        #expect(CloudSyncAvailability.unavailable.rawValue == "unavailable")
        #expect(CloudSyncAvailability.available.rawValue == "available")
        #expect(CloudSyncAvailability.restricted.rawValue == "restricted")
        #expect(CloudSyncAvailability.temporarilyUnavailable.rawValue == "temporarilyUnavailable")
    }
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}
