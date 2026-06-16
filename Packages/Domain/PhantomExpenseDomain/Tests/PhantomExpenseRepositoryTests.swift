import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("empty repository fetchAll returns no expenses")
func emptyRepositoryFetchAll() async throws {
    let result = try await PhantomExpenseRepository.empty.fetchAll()
    #expect(result.isEmpty)
}

@Test("empty repository save is a no-op")
func emptyRepositorySave() async throws {
    let expense = PhantomExpense(title: "Noop", amount: 1)
    try await PhantomExpenseRepository.empty.save(expense)
}

@Test("empty repository delete is a no-op")
func emptyRepositoryDelete() async throws {
    let id = try #require(UUID(uuidString: "66666666-6666-6666-6666-666666666666"))
    try await PhantomExpenseRepository.empty.delete(id)
}

@Test("repository forwards closures to injected implementations")
func repositoryForwardsClosures() async throws {
    let expense = PhantomExpense(
        id: try #require(UUID(uuidString: "77777777-7777-7777-7777-777777777777")),
        title: "Injected",
        amount: 42
    )
    let store = ExpenseStore()
    let repository = PhantomExpenseRepository(
        fetchAll: { await store.all() },
        save: { await store.add($0) },
        delete: { await store.remove($0) }
    )

    try await repository.save(expense)
    let afterSave = try await repository.fetchAll()
    #expect(afterSave == [expense])

    try await repository.delete(expense.id)
    let afterDelete = try await repository.fetchAll()
    #expect(afterDelete.isEmpty)
}

@Test("repository propagates thrown errors")
func repositoryPropagatesErrors() async {
    let repository = PhantomExpenseRepository(
        fetchAll: { throw SampleError.boom },
        save: { _ in },
        delete: { _ in }
    )

    await #expect(throws: SampleError.boom) {
        _ = try await repository.fetchAll()
    }
}

private enum SampleError: Error, Equatable {
    case boom
}

private actor ExpenseStore {
    private var expenses: [PhantomExpense] = []

    func all() -> [PhantomExpense] {
        expenses
    }

    func add(_ expense: PhantomExpense) {
        expenses.append(expense)
    }

    func remove(_ id: UUID) {
        expenses.removeAll { $0.id == id }
    }
}
