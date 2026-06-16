import Foundation
import Testing
@testable import MoodJournalDomain

private struct SampleError: Error, Equatable {}

@Test("empty repository fetchAll returns no entries")
func emptyRepositoryFetchAll() async throws {
    let entries = try await MoodJournalRepository.empty.fetchAll()
    #expect(entries.isEmpty)
}

@Test("empty repository save and delete are no-ops that do not throw")
func emptyRepositorySaveAndDelete() async throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000099"))
    try await MoodJournalRepository.empty.save(MoodEntry(id: id, mood: .good))
    try await MoodJournalRepository.empty.delete(id)
}

@Test("custom fetchAll closure is invoked and returns injected entries")
func customFetchAll() async throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000100"))
    let stored = [MoodEntry(id: id, mood: .stressed, spendingTotalSnapshot: 500_000)]
    let repository = MoodJournalRepository(
        fetchAll: { stored },
        save: { _ in },
        delete: { _ in }
    )

    let result = try await repository.fetchAll()
    #expect(result == stored)
}

@Test("custom save and delete closures receive the forwarded arguments")
func customSaveAndDeleteForwardArguments() async throws {
    let recorder = CallRecorder()
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000200"))
    let entry = MoodEntry(id: id, mood: .anxious, spendingTotalSnapshot: 42_000)

    let repository = MoodJournalRepository(
        fetchAll: { [] },
        save: { await recorder.recordSave($0) },
        delete: { await recorder.recordDelete($0) }
    )

    try await repository.save(entry)
    try await repository.delete(id)

    let savedEntry = await recorder.savedEntry
    let deletedID = await recorder.deletedID
    #expect(savedEntry == entry)
    #expect(deletedID == id)
}

@Test("fetchAll propagates errors thrown by the closure")
func fetchAllPropagatesError() async {
    let repository = MoodJournalRepository(
        fetchAll: { throw SampleError() },
        save: { _ in },
        delete: { _ in }
    )

    await #expect(throws: SampleError.self) {
        _ = try await repository.fetchAll()
    }
}

@Test("save propagates errors thrown by the closure")
func savePropagatesError() async {
    let repository = MoodJournalRepository(
        fetchAll: { [] },
        save: { _ in throw SampleError() },
        delete: { _ in }
    )

    await #expect(throws: SampleError.self) {
        try await repository.save(MoodEntry(mood: .good))
    }
}

@Test("delete propagates errors thrown by the closure")
func deletePropagatesError() async throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000300"))
    let repository = MoodJournalRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in throw SampleError() }
    )

    await #expect(throws: SampleError.self) {
        try await repository.delete(id)
    }
}

/// Records the arguments passed to the repository's save/delete closures
/// across the async boundary without resorting to `@unchecked Sendable`.
private actor CallRecorder {
    private(set) var savedEntry: MoodEntry?
    private(set) var deletedID: UUID?

    func recordSave(_ entry: MoodEntry) {
        savedEntry = entry
    }

    func recordDelete(_ id: UUID) {
        deletedID = id
    }
}
