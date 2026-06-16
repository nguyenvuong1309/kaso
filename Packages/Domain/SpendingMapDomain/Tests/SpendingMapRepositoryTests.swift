import Foundation
import Testing
@testable import SpendingMapDomain

private actor InMemoryEntryStore {
    private var stored: [UUID: SpendingMapEntry] = [:]

    func all() -> [SpendingMapEntry] {
        Array(stored.values)
    }

    func put(_ entry: SpendingMapEntry) {
        stored[entry.id] = entry
    }

    func remove(_ id: UUID) {
        stored[id] = nil
    }

    func count() -> Int {
        stored.count
    }
}

struct SpendingMapRepositoryTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = TimeZone(identifier: "UTC")
        return try #require(calendar.date(from: components))
    }

    private func makeEntry(id: String, occurredAt: Date) throws -> SpendingMapEntry {
        SpendingMapEntry(
            id: try #require(UUID(uuidString: id)),
            label: "Entry",
            amount: 100,
            latitude: 10,
            longitude: 106,
            occurredAt: occurredAt
        )
    }

    @Test("empty repository fetches nothing and ignores mutations")
    func emptyRepository() async throws {
        let repository = SpendingMapRepository.empty
        let initial = try await repository.fetchAll()
        #expect(initial.isEmpty)

        let occurredAt = try makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        try await repository.save(makeEntry(id: "11111111-1111-1111-1111-111111111111", occurredAt: occurredAt))
        try await repository.delete(try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111")))

        let afterMutations = try await repository.fetchAll()
        #expect(afterMutations.isEmpty)
    }

    @Test("save then fetchAll surfaces the persisted entry")
    func savePersistsEntry() async throws {
        let store = InMemoryEntryStore()
        let repository = SpendingMapRepository(
            fetchAll: { await store.all() },
            save: { await store.put($0) },
            delete: { await store.remove($0) }
        )

        let occurredAt = try makeDate(year: 2024, month: 3, day: 10, calendar: calendar)
        let entry = try makeEntry(id: "11111111-1111-1111-1111-111111111111", occurredAt: occurredAt)
        try await repository.save(entry)

        let loaded = try await repository.fetchAll()
        #expect(loaded == [entry])
    }

    @Test("delete removes only the matching entry")
    func deleteRemovesMatchingEntry() async throws {
        let store = InMemoryEntryStore()
        let repository = SpendingMapRepository(
            fetchAll: { await store.all() },
            save: { await store.put($0) },
            delete: { await store.remove($0) }
        )

        let occurredAt = try makeDate(year: 2024, month: 3, day: 10, calendar: calendar)
        let first = try makeEntry(id: "11111111-1111-1111-1111-111111111111", occurredAt: occurredAt)
        let second = try makeEntry(id: "22222222-2222-2222-2222-222222222222", occurredAt: occurredAt)
        try await repository.save(first)
        try await repository.save(second)

        try await repository.delete(first.id)

        let loaded = try await repository.fetchAll()
        #expect(loaded == [second])
    }

    @Test("fetchAll surfaces thrown errors")
    func fetchAllSurfacesErrors() async {
        struct FetchFailure: Error {}
        let repository = SpendingMapRepository(
            fetchAll: { throw FetchFailure() },
            save: { _ in },
            delete: { _ in }
        )

        await #expect(throws: FetchFailure.self) {
            _ = try await repository.fetchAll()
        }
    }

    @Test("save surfaces thrown errors")
    func saveSurfacesErrors() async throws {
        struct SaveFailure: Error {}
        let repository = SpendingMapRepository(
            fetchAll: { [] },
            save: { _ in throw SaveFailure() },
            delete: { _ in }
        )
        let occurredAt = try makeDate(year: 2024, month: 1, day: 1, calendar: calendar)
        let entry = try makeEntry(id: "11111111-1111-1111-1111-111111111111", occurredAt: occurredAt)

        await #expect(throws: SaveFailure.self) {
            try await repository.save(entry)
        }
    }

    @Test("delete surfaces thrown errors")
    func deleteSurfacesErrors() async throws {
        struct DeleteFailure: Error {}
        let repository = SpendingMapRepository(
            fetchAll: { [] },
            save: { _ in },
            delete: { _ in throw DeleteFailure() }
        )
        let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))

        await #expect(throws: DeleteFailure.self) {
            try await repository.delete(id)
        }
    }
}
