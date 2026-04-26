import ComposableArchitecture
import GoalDomain

private enum SavingGoalRepositoryKey: DependencyKey {
    static let liveValue = SavingGoalRepository.empty
    static let previewValue = SavingGoalRepository.preview
    static let testValue = SavingGoalRepository.empty
}

public extension SavingGoalRepository {
    static let preview = SavingGoalRepository(
        fetchAll: { [] },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var savingGoalRepository: SavingGoalRepository {
        get { self[SavingGoalRepositoryKey.self] }
        set { self[SavingGoalRepositoryKey.self] = newValue }
    }
}
