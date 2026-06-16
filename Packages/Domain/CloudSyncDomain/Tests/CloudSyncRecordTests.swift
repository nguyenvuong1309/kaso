import Foundation
import Testing
@testable import CloudSyncDomain

struct CloudSyncRecordTests {
    // MARK: - CloudSyncRecord init

    @Test("init stores all fields and defaults version to 1")
    func recordInitDefaults() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let payload = Data([0x01, 0x02, 0x03])
        let record = CloudSyncRecord(
            id: id,
            kind: .transaction,
            payload: payload,
            modifiedAt: modified
        )
        #expect(record.id == id)
        #expect(record.kind == .transaction)
        #expect(record.payload == payload)
        #expect(record.modifiedAt == modified)
        #expect(record.version == 1)
    }

    @Test("init keeps explicit version")
    func recordInitExplicitVersion() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let record = CloudSyncRecord(
            id: id,
            kind: .budget,
            payload: Data(),
            modifiedAt: modified,
            version: 7
        )
        #expect(record.version == 7)
        #expect(record.payload.isEmpty)
    }

    @Test("Identifiable id matches stored id")
    func recordIdentifiable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))
        let record = CloudSyncRecord(id: id, kind: .category, payload: Data(), modifiedAt: modified)
        #expect(record.id == id)
    }

    // MARK: - Equatable

    @Test("records with identical fields are equal")
    func recordEqual() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 2, day: 2, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000004"))
        let a = CloudSyncRecord(id: id, kind: .savingGoal, payload: Data([0x09]), modifiedAt: modified, version: 2)
        let b = CloudSyncRecord(id: id, kind: .savingGoal, payload: Data([0x09]), modifiedAt: modified, version: 2)
        #expect(a == b)
    }

    @Test("records differing in payload are not equal")
    func recordPayloadDiffers() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 2, day: 2, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000005"))
        let a = CloudSyncRecord(id: id, kind: .transaction, payload: Data([0x01]), modifiedAt: modified)
        let b = CloudSyncRecord(id: id, kind: .transaction, payload: Data([0x02]), modifiedAt: modified)
        #expect(a != b)
    }

    @Test("records differing in version are not equal")
    func recordVersionDiffers() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 2, day: 2, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000006"))
        let a = CloudSyncRecord(id: id, kind: .transaction, payload: Data(), modifiedAt: modified, version: 1)
        let b = CloudSyncRecord(id: id, kind: .transaction, payload: Data(), modifiedAt: modified, version: 2)
        #expect(a != b)
    }

    // MARK: - Kind

    @Test("Kind allCases covers the four sync kinds")
    func kindAllCases() {
        #expect(CloudSyncRecord.Kind.allCases == [.transaction, .budget, .category, .savingGoal])
    }

    @Test("Kind raw values are stable strings")
    func kindRawValues() {
        #expect(CloudSyncRecord.Kind.transaction.rawValue == "transaction")
        #expect(CloudSyncRecord.Kind.budget.rawValue == "budget")
        #expect(CloudSyncRecord.Kind.category.rawValue == "category")
        #expect(CloudSyncRecord.Kind.savingGoal.rawValue == "savingGoal")
    }

    @Test("Kind round-trips through Codable for every case")
    func kindCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for value in CloudSyncRecord.Kind.allCases {
            let data = try encoder.encode(value)
            let decoded = try decoder.decode(CloudSyncRecord.Kind.self, from: data)
            #expect(decoded == value)
        }
    }

    // MARK: - CloudSyncDelta

    @Test("default delta is empty")
    func deltaDefaultEmpty() {
        let delta = CloudSyncDelta()
        #expect(delta.upserts.isEmpty)
        #expect(delta.deletions.isEmpty)
        #expect(delta.isEmpty)
    }

    @Test("static empty delta is empty")
    func deltaStaticEmpty() {
        #expect(CloudSyncDelta.empty.isEmpty)
    }

    @Test("delta with only deletions is not empty")
    func deltaDeletionsOnly() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000007"))
        let delta = CloudSyncDelta(deletions: [id])
        #expect(delta.isEmpty == false)
        #expect(delta.deletions == [id])
        #expect(delta.upserts.isEmpty)
    }

    @Test("delta with only upserts is not empty")
    func deltaUpsertsOnly() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000008"))
        let record = CloudSyncRecord(id: id, kind: .transaction, payload: Data(), modifiedAt: modified)
        let delta = CloudSyncDelta(upserts: [record])
        #expect(delta.isEmpty == false)
        #expect(delta.upserts == [record])
        #expect(delta.deletions.isEmpty)
    }

    @Test("delta with both upserts and deletions is not empty")
    func deltaBoth() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let upsertId = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000009"))
        let deleteId = try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000A"))
        let record = CloudSyncRecord(id: upsertId, kind: .budget, payload: Data([0x42]), modifiedAt: modified)
        let delta = CloudSyncDelta(upserts: [record], deletions: [deleteId])
        #expect(delta.isEmpty == false)
        #expect(delta.upserts.count == 1)
        #expect(delta.deletions == [deleteId])
    }

    @Test("deltas with identical contents are equal")
    func deltaEquatable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let modified = try makeDate(year: 2026, month: 4, day: 1, calendar: calendar)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000B"))
        let record = CloudSyncRecord(id: id, kind: .category, payload: Data(), modifiedAt: modified)
        let a = CloudSyncDelta(upserts: [record], deletions: [id])
        let b = CloudSyncDelta(upserts: [record], deletions: [id])
        #expect(a == b)
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
