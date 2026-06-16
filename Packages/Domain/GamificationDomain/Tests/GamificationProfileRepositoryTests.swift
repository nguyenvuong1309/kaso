import Foundation
import Testing
@testable import GamificationDomain

private actor InMemoryProfileStore {
    private var stored: GamificationProfile?

    func read() -> GamificationProfile? {
        stored
    }

    func write(_ profile: GamificationProfile) {
        stored = profile
    }

    func reset() {
        stored = nil
    }
}

@Test("empty repository loads nil and ignores save and clear")
func emptyRepositoryReturnsNil() async throws {
    let repository = GamificationProfileRepository.empty
    let loaded = try await repository.load()
    #expect(loaded == nil)
    try await repository.save(GamificationProfile(currentStreak: 5))
    try await repository.clear()
    let afterMutations = try await repository.load()
    #expect(afterMutations == nil)
}

@Test("repository persists the saved profile for subsequent loads")
func repositoryPersistsSavedProfile() async throws {
    let store = InMemoryProfileStore()
    let repository = GamificationProfileRepository(
        load: { await store.read() },
        save: { await store.write($0) },
        clear: { await store.reset() }
    )

    let beforeSave = try await repository.load()
    #expect(beforeSave == nil)

    let profile = GamificationProfile(currentStreak: 4, longestStreak: 9, totalPoints: 600)
    try await repository.save(profile)
    let loaded = try await repository.load()
    #expect(loaded == profile)
}

@Test("repository clear removes the persisted profile")
func repositoryClearRemovesProfile() async throws {
    let store = InMemoryProfileStore()
    let repository = GamificationProfileRepository(
        load: { await store.read() },
        save: { await store.write($0) },
        clear: { await store.reset() }
    )

    try await repository.save(GamificationProfile(totalPoints: 1_000))
    try await repository.clear()
    let loaded = try await repository.load()
    #expect(loaded == nil)
}

@Test("repository load surfaces thrown errors")
func repositoryLoadSurfacesErrors() async {
    struct LoadFailure: Error {}
    let repository = GamificationProfileRepository(
        load: { throw LoadFailure() },
        save: { _ in },
        clear: {}
    )

    await #expect(throws: LoadFailure.self) {
        _ = try await repository.load()
    }
}
