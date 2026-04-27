import ComposableArchitecture
import PhantomExpenseDomain

private enum PhantomExpenseRepositoryKey: DependencyKey {
    static let liveValue = PhantomExpenseRepository.empty
    static let previewValue = PhantomExpenseRepository.preview
    static let testValue = PhantomExpenseRepository.empty
}

public extension PhantomExpenseRepository {
    static let preview = PhantomExpenseRepository(
        fetchAll: {
            [
                PhantomExpense(
                    title: "Huỷ subscription không dùng",
                    amount: 300_000,
                    category: .subscription,
                    avoidedAt: .now
                ),
                PhantomExpense(
                    title: "Bỏ giỏ hàng sneaker",
                    amount: 1_500_000,
                    category: .cart,
                    avoidedAt: .now
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var phantomExpenseRepository: PhantomExpenseRepository {
        get { self[PhantomExpenseRepositoryKey.self] }
        set { self[PhantomExpenseRepositoryKey.self] = newValue }
    }
}
