import Foundation
import Testing
@testable import CloudSyncDomain

struct CloudSyncClientTests {
    // MARK: - CloudSyncError

    @Test("error cases are distinct and self-equal")
    func errorEquatable() {
        let all: [CloudSyncError] = [
            .notAvailable, .authenticationRequired, .quotaExceeded, .networkFailure, .unknown,
        ]
        for (index, error) in all.enumerated() {
            #expect(error == all[index])
            for (otherIndex, other) in all.enumerated() where otherIndex != index {
                #expect(error != other)
            }
        }
    }

    // MARK: - empty client

    @Test("empty client reports unavailable")
    func emptyAvailability() async {
        let availability = await CloudSyncClient.empty.availability()
        #expect(availability == .unavailable)
    }

    @Test("empty client returns empty delta when fetching")
    func emptyFetch() async throws {
        let delta = try await CloudSyncClient.empty.fetchChanges(nil)
        #expect(delta.isEmpty)
    }

    @Test("empty client throws notAvailable on upload")
    func emptyUploadThrows() async {
        await #expect(throws: CloudSyncError.notAvailable) {
            try await CloudSyncClient.empty.upload(.empty)
        }
    }

    // MARK: - preview client

    @Test("preview client reports available")
    func previewAvailability() async {
        let availability = await CloudSyncClient.preview.availability()
        #expect(availability == .available)
    }

    @Test("preview client fetch returns empty and upload succeeds")
    func previewFetchAndUpload() async throws {
        let delta = try await CloudSyncClient.preview.fetchChanges(nil)
        #expect(delta.isEmpty)
        try await CloudSyncClient.preview.upload(.empty)
    }

    // MARK: - custom client wiring

    @Test("custom client routes availability, fetch since, and upload payloads")
    func customClientWiring() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let since = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
        let modified = try makeDate(year: 2026, month: 6, day: 2, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000FF"))
        let record = CloudSyncRecord(id: id, kind: .transaction, payload: Data([0x01]), modifiedAt: modified)
        let returnedDelta = CloudSyncDelta(upserts: [record])
        let recorder = CallRecorder()

        let client = CloudSyncClient(
            availability: { .restricted },
            fetchChanges: { date in
                await recorder.recordFetch(since: date)
                return returnedDelta
            },
            upload: { delta in await recorder.recordUpload(delta) }
        )

        let availability = await client.availability()
        #expect(availability == .restricted)

        let delta = try await client.fetchChanges(since)
        #expect(delta == returnedDelta)
        let fetchedSince = await recorder.fetchedSince
        #expect(fetchedSince == since)

        try await client.upload(returnedDelta)
        let uploaded = await recorder.uploadedDelta
        #expect(uploaded == returnedDelta)
    }

    @Test("custom client can throw a specific error from upload")
    func customUploadThrows() async {
        let client = CloudSyncClient(
            availability: { .temporarilyUnavailable },
            fetchChanges: { _ in .empty },
            upload: { _ in throw CloudSyncError.quotaExceeded }
        )
        await #expect(throws: CloudSyncError.quotaExceeded) {
            try await client.upload(.empty)
        }
    }

    @Test("custom client can throw from fetch")
    func customFetchThrows() async {
        let client = CloudSyncClient(
            availability: { .available },
            fetchChanges: { _ in throw CloudSyncError.networkFailure },
            upload: { _ in }
        )
        await #expect(throws: CloudSyncError.networkFailure) {
            _ = try await client.fetchChanges(nil)
        }
    }
}

private actor CallRecorder {
    private(set) var fetchedSince: Date?
    private(set) var uploadedDelta: CloudSyncDelta?

    func recordFetch(since: Date?) { fetchedSince = since }
    func recordUpload(_ delta: CloudSyncDelta) { uploadedDelta = delta }
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
