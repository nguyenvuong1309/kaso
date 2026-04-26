import ComposableArchitecture
import TransactionDomain

private enum TransactionCategoryRepositoryKey: DependencyKey {
    static let liveValue = TransactionCategoryRepository.empty
    static let previewValue = TransactionCategoryRepository.preview
    static let testValue = TransactionCategoryRepository.empty
}

public extension TransactionCategoryRepository {
    static let preview = TransactionCategoryRepository(
        fetchCustomCategories: { [] },
        saveCustomCategories: { _ in }
    )
}

public extension DependencyValues {
    var transactionCategoryRepository: TransactionCategoryRepository {
        get { self[TransactionCategoryRepositoryKey.self] }
        set { self[TransactionCategoryRepositoryKey.self] = newValue }
    }
}
