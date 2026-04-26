import ComposableArchitecture
import Foundation
import TransactionDomain

private enum TransactionRepositoryKey: DependencyKey {
    static let liveValue = TransactionRepository.empty
    static let previewValue = TransactionRepository.preview
    static let testValue = TransactionRepository.empty
}

public extension TransactionRepository {
    static let preview = TransactionRepository(
        fetchAll: {
            [
                Transaction.sampleExpense(
                    amount: 45_000,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 20_000_000,
                    kind: .income,
                    category: .salary,
                    occurredAt: Date()
                ),
            ]
        },
        save: { _ in }
    )
}

public extension DependencyValues {
    var transactionRepository: TransactionRepository {
        get { self[TransactionRepositoryKey.self] }
        set { self[TransactionRepositoryKey.self] = newValue }
    }
}
