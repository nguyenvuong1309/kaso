import Foundation
import Testing
import TransactionDomain
@testable import BudgetDomain

@Test("empty repository fetches an empty list")
func emptyRepositoryFetchAllReturnsEmpty() async throws {
    let budgets = try await BudgetRepository.empty.fetchAll()
    #expect(budgets.isEmpty)
}

@Test("empty repository saveAll is a no-op")
func emptyRepositorySaveAllNoOp() async throws {
    try await BudgetRepository.empty.saveAll([
        Budget(category: .food, monthlyLimit: 1_000_000),
    ])
}

@Test("repository forwards fetched budgets from its closure")
func repositoryForwardsFetch() async throws {
    let expected = [
        Budget(category: .food, monthlyLimit: 1_000_000, spent: 200_000),
        Budget(category: .transport, monthlyLimit: 500_000),
    ]
    let repository = BudgetRepository(
        fetchAll: { expected },
        saveAll: { _ in }
    )

    let result = try await repository.fetchAll()
    #expect(result == expected)
}

@Test("repository passes saved budgets to its closure")
func repositoryForwardsSave() async throws {
    let recorded = Recorder()
    let repository = BudgetRepository(
        fetchAll: { [] },
        saveAll: { await recorded.store($0) }
    )

    let toSave = [Budget(category: .health, monthlyLimit: 300_000, spent: 50_000)]
    try await repository.saveAll(toSave)

    #expect(await recorded.value == toSave)
}

@Test("repository propagates fetch errors")
func repositoryPropagatesFetchError() async {
    let repository = BudgetRepository(
        fetchAll: { throw SampleError.failure },
        saveAll: { _ in }
    )

    await #expect(throws: SampleError.failure) {
        _ = try await repository.fetchAll()
    }
}

@Test("repository propagates save errors")
func repositoryPropagatesSaveError() async {
    let repository = BudgetRepository(
        fetchAll: { [] },
        saveAll: { _ in throw SampleError.failure }
    )

    await #expect(throws: SampleError.failure) {
        try await repository.saveAll([])
    }
}

private enum SampleError: Error, Equatable {
    case failure
}

private actor Recorder {
    private(set) var value: [Budget] = []

    func store(_ budgets: [Budget]) {
        value = budgets
    }
}
