import Foundation
import Testing
@testable import FreelancerDomain

private let fixedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")

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

@Test("empty repository load returns nil")
func emptyRepositoryLoadReturnsNil() async throws {
    let repository = FreelancerProfileRepository.empty
    let loaded = try await repository.load()
    #expect(loaded == nil)
}

@Test("empty repository save is a no-op that does not throw")
func emptyRepositorySaveNoOp() async throws {
    let repository = FreelancerProfileRepository.empty
    let id = try #require(fixedID)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let profile = FreelancerProfile(id: id, createdAt: created, updatedAt: created)
    try await repository.save(profile)
}

@Test("injected closures are invoked by load and save")
func injectedClosuresInvoked() async throws {
    let id = try #require(fixedID)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let stored = FreelancerProfile(
        id: id,
        monthlyIncomes: [
            MonthlyIncome(month: YearMonth(year: 2026, month: 3), grossAmount: 11_000_000),
        ],
        smoothingWindow: .sixMonths,
        bufferBalance: 5_000_000,
        bufferTargetMultiplier: 3,
        workType: .onlineSeller,
        taxRate: 0.12,
        createdAt: created,
        updatedAt: created
    )

    let box = SavedProfileBox()
    let repository = FreelancerProfileRepository(
        load: { stored },
        save: { profile in await box.set(profile) }
    )

    let loaded = try await repository.load()
    #expect(loaded == stored)

    try await repository.save(stored)
    let saved = await box.value
    #expect(saved == stored)
}

@Test("repository load propagates thrown errors")
func repositoryLoadPropagatesError() async {
    let repository = FreelancerProfileRepository(
        load: { throw RepositoryTestError.failure },
        save: { _ in }
    )

    await #expect(throws: RepositoryTestError.failure) {
        _ = try await repository.load()
    }
}

@Test("repository save propagates thrown errors")
func repositorySavePropagatesError() async throws {
    let repository = FreelancerProfileRepository(
        load: { nil },
        save: { _ in throw RepositoryTestError.failure }
    )
    let id = try #require(fixedID)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let profile = FreelancerProfile(id: id, createdAt: created, updatedAt: created)

    await #expect(throws: RepositoryTestError.failure) {
        try await repository.save(profile)
    }
}

private enum RepositoryTestError: Error, Equatable {
    case failure
}

private actor SavedProfileBox {
    private(set) var value: FreelancerProfile?

    func set(_ profile: FreelancerProfile) {
        value = profile
    }
}
