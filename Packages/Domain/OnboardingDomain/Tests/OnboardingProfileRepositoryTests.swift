import Foundation
import Testing
import TransactionDomain
@testable import OnboardingDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
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

private actor ProfileStore {
    private var stored: OnboardingProfile?

    init(initial: OnboardingProfile? = nil) {
        stored = initial
    }

    func get() -> OnboardingProfile? { stored }
    func set(_ profile: OnboardingProfile) { stored = profile }
    func reset() { stored = nil }
}

private func makeProfile(completedAt date: Date) -> OnboardingProfile {
    OnboardingProfile(
        monthlyIncome: 10_000_000,
        primaryCategories: [.food],
        financialGoal: .trackCashflow,
        monthlySavingsTarget: 2_000_000,
        suggestedBudgets: [BudgetSuggestion(category: .food, monthlyLimit: 8_000_000)],
        completedAt: date
    )
}

@Test("empty repository loads nil and ignores save and clear")
func emptyRepositoryLoadsNil() async throws {
    let repository = OnboardingProfileRepository.empty
    let date = try makeDate(year: 2026, month: 6, day: 16)

    let loaded = try await repository.load()
    #expect(loaded == nil)

    // save and clear are no-ops on the empty repository and must not throw.
    try await repository.save(makeProfile(completedAt: date))
    try await repository.clear()

    let stillNil = try await repository.load()
    #expect(stillNil == nil)
}

@Test("save then load returns the persisted profile")
func repositorySaveThenLoad() async throws {
    let store = ProfileStore()
    let repository = OnboardingProfileRepository(
        load: { await store.get() },
        save: { await store.set($0) },
        clear: { await store.reset() }
    )
    let date = try makeDate(year: 2026, month: 6, day: 16)
    let profile = makeProfile(completedAt: date)

    let before = try await repository.load()
    #expect(before == nil)

    try await repository.save(profile)
    let after = try await repository.load()
    #expect(after == profile)
}

@Test("clear removes a previously saved profile")
func repositoryClearRemovesProfile() async throws {
    let date = try makeDate(year: 2026, month: 6, day: 16)
    let store = ProfileStore(initial: makeProfile(completedAt: date))
    let repository = OnboardingProfileRepository(
        load: { await store.get() },
        save: { await store.set($0) },
        clear: { await store.reset() }
    )

    let loaded = try await repository.load()
    #expect(loaded != nil)

    try await repository.clear()
    let cleared = try await repository.load()
    #expect(cleared == nil)
}

@Test("save overwrites a previously persisted profile")
func repositorySaveOverwrites() async throws {
    let store = ProfileStore()
    let repository = OnboardingProfileRepository(
        load: { await store.get() },
        save: { await store.set($0) },
        clear: { await store.reset() }
    )
    let first = makeProfile(completedAt: try makeDate(year: 2026, month: 1, day: 1))
    var second = makeProfile(completedAt: try makeDate(year: 2026, month: 12, day: 31))
    second.monthlyIncome = 25_000_000

    try await repository.save(first)
    try await repository.save(second)

    let loaded = try await repository.load()
    #expect(loaded == second)
    #expect(loaded?.monthlyIncome == Decimal(25_000_000))
}

private struct RepositoryError: Error, Equatable {}

@Test("propagates errors thrown by the load closure")
func repositoryPropagatesLoadError() async {
    let repository = OnboardingProfileRepository(
        load: { throw RepositoryError() },
        save: { _ in },
        clear: {}
    )

    await #expect(throws: RepositoryError.self) {
        _ = try await repository.load()
    }
}
