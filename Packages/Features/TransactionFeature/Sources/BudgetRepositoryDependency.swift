import BudgetDomain
import ComposableArchitecture

private enum BudgetRepositoryKey: DependencyKey {
    static let liveValue = BudgetRepository.empty
    static let previewValue = BudgetRepository.preview
    static let testValue = BudgetRepository.empty
}

public extension BudgetRepository {
    static let preview = BudgetRepository(
        fetchAll: { [] },
        saveAll: { _ in }
    )
}

public extension DependencyValues {
    var budgetRepository: BudgetRepository {
        get { self[BudgetRepositoryKey.self] }
        set { self[BudgetRepositoryKey.self] = newValue }
    }
}
