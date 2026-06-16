import Foundation
import Testing
@testable import GiftTrackerDomain

@Test("empty repository fetchAll returns no records")
func emptyFetchAll() async throws {
    let records = try await GiftTrackerRepository.empty.fetchAll()
    #expect(records.isEmpty)
}

@Test("empty repository save and delete are no-ops that do not throw")
func emptySaveAndDelete() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeRepoDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let id = try #require(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"))
    let record = GiftRecord(
        id: id, personName: "A", eventKind: .tet, direction: .given,
        amount: 100, eventDate: date, createdAt: date
    )

    try await GiftTrackerRepository.empty.save(record)
    try await GiftTrackerRepository.empty.delete(id)
}

@Test("preview repository returns three seeded records")
func previewFetchAll() async throws {
    let records = try await GiftTrackerRepository.preview.fetchAll()
    #expect(records.count == 3)
    #expect(records.contains { $0.personName == "Nguyễn Văn Hùng" })
    #expect(records.contains { $0.personName == "Trần Thị Mai" })
}

@Test("preview repository seeds expected directions and amounts")
func previewSeedContents() async throws {
    let records = try await GiftTrackerRepository.preview.fetchAll()

    let given = records.filter { $0.direction == .given }
    let received = records.filter { $0.direction == .received }
    #expect(given.count == 1)
    #expect(received.count == 2)

    let wedding = try #require(records.first { $0.eventKind == .wedding })
    #expect(wedding.amount == 1_000_000)
    #expect(wedding.note == "Đám cưới tại Long An")
}

@Test("custom repository routes through injected closures")
func customClosures() async throws {
    let calendar = Calendar(identifier: .gregorian)
    let date = try makeRepoDate(year: 2026, month: 5, day: 5, calendar: calendar)
    let id = try #require(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"))
    let seeded = GiftRecord(
        id: id, personName: "Seeded", eventKind: .birthday, direction: .received,
        amount: 250_000, eventDate: date, createdAt: date
    )

    let store = RecordStore()
    let repository = GiftTrackerRepository(
        fetchAll: { await store.all() },
        save: { await store.append($0) },
        delete: { await store.remove($0) }
    )

    try await repository.save(seeded)
    let afterSave = try await repository.fetchAll()
    #expect(afterSave == [seeded])

    try await repository.delete(id)
    let afterDelete = try await repository.fetchAll()
    #expect(afterDelete.isEmpty)
}

@Test("custom repository propagates thrown errors")
func customThrows() async {
    let repository = GiftTrackerRepository(
        fetchAll: { throw RepoError.boom },
        save: { _ in throw RepoError.boom },
        delete: { _ in throw RepoError.boom }
    )

    await #expect(throws: RepoError.boom) {
        _ = try await repository.fetchAll()
    }
}

// MARK: - Test doubles

private enum RepoError: Error, Equatable {
    case boom
}

private actor RecordStore {
    private var records: [GiftRecord] = []

    func all() -> [GiftRecord] { records }
    func append(_ record: GiftRecord) { records.append(record) }
    func remove(_ id: UUID) { records.removeAll { $0.id == id } }
}

private func makeRepoDate(
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
