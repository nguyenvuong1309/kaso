import Foundation
import Testing
@testable import RoundUpDomain

@Test("empty repository loadRule returns default rule")
func emptyRepositoryLoadRule() async throws {
    let rule = try await RoundUpRepository.empty.loadRule()
    #expect(rule == RoundUpRule())
}

@Test("empty repository fetchEntries returns no entries")
func emptyRepositoryFetchEntries() async throws {
    let entries = try await RoundUpRepository.empty.fetchEntries()
    #expect(entries.isEmpty)
}

@Test("empty repository mutating closures are no-ops that do not throw")
func emptyRepositoryNoOps() async throws {
    let repo = RoundUpRepository.empty
    try await repo.saveRule(RoundUpRule(isEnabled: true))
    try await repo.saveEntry(
        RoundUpEntry(
            originalAmount: 1,
            roundedAmount: 1_000,
            contribution: 999,
            step: .oneThousand
        )
    )
    try await repo.deleteEntry(UUID())
    try await repo.clearAll()
    // Reaching here without throwing is the assertion.
    #expect(Bool(true))
}

@Test("custom repository routes calls to provided closures")
func customRepositoryRoutesCalls() async throws {
    let storedRule = RoundUpRule(isEnabled: true, step: .fiftyThousand)
    let storedEntry = RoundUpEntry(
        originalAmount: 5_000,
        roundedAmount: 10_000,
        contribution: 5_000,
        step: .fiveThousand
    )

    let repo = RoundUpRepository(
        loadRule: { storedRule },
        saveRule: { _ in },
        fetchEntries: { [storedEntry] },
        saveEntry: { _ in },
        deleteEntry: { _ in },
        clearAll: {}
    )

    let loaded = try await repo.loadRule()
    let fetched = try await repo.fetchEntries()

    #expect(loaded == storedRule)
    #expect(fetched == [storedEntry])
}

@Test("repository closures propagate thrown errors")
func repositoryPropagatesErrors() async {
    struct SampleError: Error, Equatable {}

    let repo = RoundUpRepository(
        loadRule: { throw SampleError() },
        saveRule: { _ in throw SampleError() },
        fetchEntries: { throw SampleError() },
        saveEntry: { _ in throw SampleError() },
        deleteEntry: { _ in throw SampleError() },
        clearAll: { throw SampleError() }
    )

    await #expect(throws: SampleError.self) {
        _ = try await repo.loadRule()
    }
    await #expect(throws: SampleError.self) {
        try await repo.clearAll()
    }
}
