import ComposableArchitecture
import SwiftUI
import TransactionDomain
import WellnessDomain

#Preview("Hours Of Life Light") {
    HoursOfLifeView(store: previewStore)
}

#Preview("Hours Of Life Dark") {
    HoursOfLifeView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Hours Of Life Dynamic Type XL") {
    HoursOfLifeView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

#Preview("Hours Of Life Empty") {
    HoursOfLifeView(store: emptyPreviewStore)
}

@MainActor
private var previewStore: StoreOf<HoursOfLifeFeature> {
    Store(
        initialState: HoursOfLifeFeature.State(
            configuration: HoursOfLifeConfiguration(
                monthlyNetIncome: 18_000_000,
                averageMonthlyWorkHours: 160
            ),
            recentExpenses: [
                Transaction(
                    amount: 65_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 320_000,
                    kind: .expense,
                    category: .transport,
                    occurredAt: Date().addingTimeInterval(-3600 * 5)
                ),
                Transaction(
                    amount: 1_200_000,
                    kind: .expense,
                    category: .shopping,
                    occurredAt: Date().addingTimeInterval(-3600 * 24)
                ),
            ],
            calculatorAmountText: "150000",
            monthlyNetIncomeText: "18000000",
            monthlyWorkHoursText: "160"
        )
    ) {
        HoursOfLifeFeature()
    }
}

@MainActor
private var emptyPreviewStore: StoreOf<HoursOfLifeFeature> {
    Store(
        initialState: HoursOfLifeFeature.State()
    ) {
        HoursOfLifeFeature()
    }
}
