import Foundation
import Testing
@testable import LegacyDomain

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
    components.timeZone = TimeZone(identifier: "UTC")
    return try #require(calendar.date(from: components))
}

private struct RepositoryError: Error, Equatable {}

// MARK: - empty repository

@Test("empty repository load returns nil")
func emptyRepositoryLoadReturnsNil() async throws {
    let repository = LegacyVaultRepository.empty
    let loaded = try await repository.load()
    #expect(loaded == nil)
}

@Test("empty repository save is a no-op and does not throw")
func emptyRepositorySaveNoOp() async throws {
    let repository = LegacyVaultRepository.empty
    try await repository.save(.preview)
    // No throw, and load still yields nil afterwards.
    let loaded = try await repository.load()
    #expect(loaded == nil)
}

// MARK: - custom closures

@Test("repository load returns the injected vault")
func repositoryLoadReturnsInjectedVault() async throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    let created = try makeDate(year: 2026, month: 2, day: 1)
    let vault = LegacyVault(id: id, owner: "Loaded", createdAt: created, lastUpdatedAt: created)

    let repository = LegacyVaultRepository(
        load: { vault },
        save: { _ in }
    )

    let loaded = try await repository.load()
    #expect(loaded == vault)
    #expect(loaded?.owner == "Loaded")
}

@Test("repository save forwards the vault to the injected closure")
func repositorySaveForwardsVault() async throws {
    let box = SavedBox()
    let repository = LegacyVaultRepository(
        load: { nil },
        save: { vault in await box.store(vault) }
    )

    try await repository.save(.preview)
    let saved = await box.value
    #expect(saved == LegacyVault.preview)
}

@Test("repository load propagates errors")
func repositoryLoadPropagatesError() async {
    let repository = LegacyVaultRepository(
        load: { throw RepositoryError() },
        save: { _ in }
    )

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.load()
    }
}

@Test("repository save propagates errors")
func repositorySavePropagatesError() async {
    let repository = LegacyVaultRepository(
        load: { nil },
        save: { _ in throw RepositoryError() }
    )

    await #expect(throws: RepositoryError.self) {
        try await repository.save(.empty)
    }
}

@Test("repository round trips a saved vault through an in-memory store")
func repositoryRoundTripInMemory() async throws {
    let box = SavedBox()
    let repository = LegacyVaultRepository(
        load: { await box.value },
        save: { vault in await box.store(vault) }
    )

    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
    let created = try makeDate(year: 2026, month: 3, day: 3)
    let vault = LegacyVault(id: id, owner: "Persisted", createdAt: created, lastUpdatedAt: created)

    #expect(try await repository.load() == nil)
    try await repository.save(vault)
    let loaded = try await repository.load()
    #expect(loaded == vault)
}

private actor SavedBox {
    private(set) var value: LegacyVault?

    func store(_ vault: LegacyVault) {
        value = vault
    }
}
