import ComposableArchitecture
import Foundation
import MoodJournalDomain
import Testing
@testable import MoodJournalFeature

@MainActor
@Test("loads entries on task and sorts newest first")
func loadsEntriesOnTask() async throws {
    let older = MoodEntry(mood: .good, spendingTotalSnapshot: 100_000, recordedAt: Date(timeIntervalSince1970: 1_000))
    let newer = MoodEntry(mood: .stressed, spendingTotalSnapshot: 500_000, recordedAt: Date(timeIntervalSince1970: 2_000))
    let store = TestStore(initialState: MoodJournalFeature.State()) {
        MoodJournalFeature()
    } withDependencies: {
        $0.moodJournalRepository.fetchAll = { [older, newer] }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.entriesLoaded([older, newer])) {
        $0.isLoading = false
        $0.entries = IdentifiedArray(uniqueElements: [newer, older])
    }
}

@MainActor
@Test("saving an entry validates and persists")
func savingEntryPersists() async throws {
    let referenceDate = Date(timeIntervalSince1970: 5_000)
    let entryID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let saved = LockIsolated<[MoodEntry]>([])
    let store = TestStore(
        initialState: MoodJournalFeature.State(
            isEditorPresented: true,
            selectedMood: .stressed,
            spendingTotalText: "650.000",
            noteText: "Deadline"
        )
    ) {
        MoodJournalFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = UUIDGenerator { entryID }
        $0.moodJournalRepository.save = { entry in
            saved.withValue { $0.append(entry) }
        }
    }

    let expected = MoodEntry(
        id: entryID,
        mood: .stressed,
        spendingTotalSnapshot: 650_000,
        transactionIDs: [],
        note: "Deadline",
        recordedAt: referenceDate
    )

    await store.send(.saveButtonTapped) {
        $0.isEditorPresented = false
    }
    await store.receive(.entrySaved(expected)) {
        $0.entries = IdentifiedArray(uniqueElements: [expected])
    }

    #expect(saved.value == [expected])
}

@MainActor
@Test("deleting an entry removes it from state")
func deletingEntryRemoves() async throws {
    let entry = MoodEntry(mood: .anxious, spendingTotalSnapshot: 300_000)
    let store = TestStore(
        initialState: MoodJournalFeature.State(
            entries: IdentifiedArray(uniqueElements: [entry])
        )
    ) {
        MoodJournalFeature()
    } withDependencies: {
        $0.moodJournalRepository.delete = { _ in }
    }

    await store.send(.deleteButtonTapped(entry.id))
    await store.receive(.entryDeleted(entry.id)) {
        $0.entries = []
    }
}
