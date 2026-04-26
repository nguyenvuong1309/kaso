import SwiftUI
import ComposableArchitecture
import DebtDomain

#Preview("Debt Light") {
    DebtView(store: previewStore)
}

#Preview("Debt Dark") {
    DebtView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Debt Dynamic Type XL") {
    DebtView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<DebtFeature> {
    let date = Date(timeIntervalSinceReferenceDate: 799_200_000)
    let debt = Debt(
        name: "Vay mua nhà",
        type: .mortgage,
        principal: 1_000_000_000,
        annualInterestRatePercent: 8,
        termMonths: 240,
        startDate: date,
        paymentDay: 5,
        createdAt: date
    )

    return Store(
        initialState: DebtFeature.State(
            debts: IdentifiedArray(uniqueElements: [debt]),
            selectedDebtID: debt.id,
            referenceDate: date,
            extraMonthlyPaymentText: "5.000.000"
        )
    ) {
        DebtFeature()
    }
}
