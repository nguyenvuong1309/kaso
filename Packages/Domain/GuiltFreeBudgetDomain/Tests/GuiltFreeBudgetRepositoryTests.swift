import Foundation
import Testing
@testable import GuiltFreeBudgetDomain

// MARK: - GuiltFreeBudgetRepository

@Test("empty repository load returns a default configuration")
func emptyRepositoryLoadsDefault() async throws {
    let repository = GuiltFreeBudgetRepository.empty

    let config = try await repository.load()

    #expect(config.monthlyIncome == 0)
    #expect(config.monthlySavingsTarget == 0)
    #expect(config.emergencyFundMonthlyContribution == 0)
    #expect(config.fixedCosts.isEmpty)
}

@Test("empty repository save performs no-op without throwing")
func emptyRepositorySaveIsNoOp() async throws {
    let repository = GuiltFreeBudgetRepository.empty

    try await repository.save(GuiltFreeBudgetConfiguration(monthlyIncome: 10_000_000))
}

@Test("custom repository routes load and save to provided closures")
func customRepositoryRoutesClosures() async throws {
    let stored = LockedConfig()
    let seed = GuiltFreeBudgetConfiguration(monthlyIncome: 12_345_000)
    await stored.set(seed)

    let repository = GuiltFreeBudgetRepository(
        load: { await stored.get() },
        save: { await stored.set($0) }
    )

    let loaded = try await repository.load()
    #expect(loaded.monthlyIncome == 12_345_000)

    let updated = GuiltFreeBudgetConfiguration(monthlyIncome: 99_000_000)
    try await repository.save(updated)
    let reloaded = try await repository.load()
    #expect(reloaded.monthlyIncome == 99_000_000)
}

@Test("repository load propagates thrown errors")
func repositoryLoadPropagatesError() async {
    let repository = GuiltFreeBudgetRepository(
        load: { throw RepositoryTestError.boom },
        save: { _ in }
    )

    await #expect(throws: RepositoryTestError.self) {
        _ = try await repository.load()
    }
}

@Test("repository save propagates thrown errors")
func repositorySavePropagatesError() async {
    let repository = GuiltFreeBudgetRepository(
        load: { GuiltFreeBudgetConfiguration() },
        save: { _ in throw RepositoryTestError.boom }
    )

    await #expect(throws: RepositoryTestError.self) {
        try await repository.save(GuiltFreeBudgetConfiguration())
    }
}

// MARK: - Helpers

private enum RepositoryTestError: Error {
    case boom
}

private actor LockedConfig {
    private var value = GuiltFreeBudgetConfiguration()

    func get() -> GuiltFreeBudgetConfiguration {
        value
    }

    func set(_ newValue: GuiltFreeBudgetConfiguration) {
        value = newValue
    }
}
