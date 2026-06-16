import Foundation
import Testing
@testable import DebtDomain

@Suite("DebtRepository")
struct DebtRepositoryTests {
    @Test("empty repository returns no debts and no-ops on save/delete")
    func emptyRepository() async throws {
        let repository = DebtRepository.empty
        let all = try await repository.fetchAll()
        #expect(all.isEmpty)
        // Should not throw.
        try await repository.save(makeDebt())
        try await repository.delete(UUID())
    }

    @Test("custom closures are invoked with provided arguments")
    func closuresForwardArguments() async throws {
        let debt = makeDebt()
        let store = DebtStore()

        let repository = DebtRepository(
            fetchAll: { await store.debts },
            save: { await store.add($0) },
            delete: { await store.remove($0) }
        )

        try await repository.save(debt)
        let fetched = try await repository.fetchAll()
        #expect(fetched == [debt])

        try await repository.delete(debt.id)
        #expect(await store.deletedIDs == [debt.id])
    }

    @Test("fetchAll can surface thrown errors")
    func fetchAllPropagatesError() async {
        let repository = DebtRepository(
            fetchAll: { throw SampleError.boom },
            save: { _ in },
            delete: { _ in }
        )
        await #expect(throws: SampleError.boom) {
            _ = try await repository.fetchAll()
        }
    }

    private func makeDebt() -> Debt {
        Debt(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            name: "Vay",
            type: .personalLoan,
            principal: 10_000_000,
            annualInterestRatePercent: 5,
            termMonths: 12,
            startDate: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 0),
            createdAt: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 0)
        )
    }
}

private enum SampleError: Error, Equatable {
    case boom
}

private actor DebtStore {
    private(set) var debts: [Debt] = []
    private(set) var deletedIDs: [UUID] = []

    func add(_ debt: Debt) {
        debts.append(debt)
    }

    func remove(_ id: UUID) {
        deletedIDs.append(id)
        debts.removeAll { $0.id == id }
    }
}
