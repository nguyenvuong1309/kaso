import SwiftUI
import ComposableArchitecture
import PhantomExpenseDomain

#Preview("Phantom Expense Light") {
    PhantomExpenseView(store: previewStore)
}

#Preview("Phantom Expense Dark") {
    PhantomExpenseView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Phantom Expense Dynamic Type XL") {
    PhantomExpenseView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<PhantomExpenseFeature> {
    Store(
        initialState: PhantomExpenseFeature.State(
            expenses: IdentifiedArray(uniqueElements: [
                PhantomExpense(
                    title: "Huỷ subscription không dùng",
                    amount: 300_000,
                    category: .subscription,
                    avoidedAt: Date()
                ),
                PhantomExpense(
                    title: "Bỏ giỏ hàng sneaker",
                    amount: 1_500_000,
                    category: .cart,
                    avoidedAt: Date()
                ),
            ]),
            referenceDate: Date()
        )
    ) {
        PhantomExpenseFeature()
    }
}
