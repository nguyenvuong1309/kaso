import Foundation
import Testing
@testable import MoneyTherapistDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.calendar = calendar
    components.timeZone = TimeZone(identifier: "UTC")
    return try #require(components.date)
}

private let repoID = try #require(UUID(uuidString: "11111111-0000-0000-0000-000000000001"))

private struct RepositoryError: Error, Equatable {}

@Test("empty repository fetchAll returns an empty array")
func emptyFetchAll() async throws {
    let result = try await TherapistRepository.empty.fetchAll()
    #expect(result.isEmpty)
}

@Test("empty repository save is a no-op that does not throw")
func emptySaveDoesNotThrow() async throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let reflection = TherapistReflection(id: repoID, topic: .guilt, recordedAt: recordedAt)
    try await TherapistRepository.empty.save(reflection)
    // Still empty after a save — the empty repository never persists.
    let result = try await TherapistRepository.empty.fetchAll()
    #expect(result.isEmpty)
}

@Test("empty repository delete is a no-op that does not throw")
func emptyDeleteDoesNotThrow() async throws {
    try await TherapistRepository.empty.delete(repoID)
}

@Test("init wires fetchAll to its supplied closure")
func initWiresFetchAll() async throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let stored = TherapistReflection(id: repoID, topic: .stressTrigger, recordedAt: recordedAt)
    let repository = TherapistRepository(
        fetchAll: { [stored] },
        save: { _ in },
        delete: { _ in }
    )
    let result = try await repository.fetchAll()
    #expect(result == [stored])
}

@Test("init wires save to receive the exact reflection passed in")
func initWiresSave() async throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16, hour: 7)
    let reflection = TherapistReflection(
        id: repoID,
        topic: .comparisonAnxiety,
        note: "noted",
        recordedAt: recordedAt
    )
    let recorder = Recorder<TherapistReflection>()
    let repository = TherapistRepository(
        fetchAll: { [] },
        save: { await recorder.record($0) },
        delete: { _ in }
    )
    try await repository.save(reflection)
    #expect(await recorder.value == reflection)
}

@Test("init wires delete to receive the exact id passed in")
func initWiresDelete() async throws {
    let recorder = Recorder<UUID>()
    let repository = TherapistRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { await recorder.record($0) }
    )
    try await repository.delete(repoID)
    #expect(await recorder.value == repoID)
}

@Test("fetchAll propagates errors thrown by its closure")
func fetchAllPropagatesError() async {
    let repository = TherapistRepository(
        fetchAll: { throw RepositoryError() },
        save: { _ in },
        delete: { _ in }
    )
    await #expect(throws: RepositoryError.self) {
        _ = try await repository.fetchAll()
    }
}

@Test("save propagates errors thrown by its closure")
func savePropagatesError() async throws {
    let recordedAt = try makeDate(year: 2026, month: 6, day: 16)
    let reflection = TherapistReflection(id: repoID, topic: .guilt, recordedAt: recordedAt)
    let repository = TherapistRepository(
        fetchAll: { [] },
        save: { _ in throw RepositoryError() },
        delete: { _ in }
    )
    await #expect(throws: RepositoryError.self) {
        try await repository.save(reflection)
    }
}

@Test("delete propagates errors thrown by its closure")
func deletePropagatesError() async {
    let repository = TherapistRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in throw RepositoryError() }
    )
    await #expect(throws: RepositoryError.self) {
        try await repository.delete(repoID)
    }
}

/// An actor so escaping `@Sendable` closures can record what they were invoked
/// with under Swift 6 strict concurrency, without `@unchecked Sendable`.
private actor Recorder<Value: Sendable> {
    private(set) var value: Value?
    func record(_ value: Value) { self.value = value }
}
