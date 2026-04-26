import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import WealthDomain

#Preview("Wealth Light") {
    WealthView(store: previewStore)
}

#Preview("Wealth Dark") {
    WealthView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Wealth Dynamic Type XL") {
    WealthView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<WealthFeature> {
    Store(
        initialState: WealthFeature.State(
            assets: IdentifiedArray(uniqueElements: [
                Asset(name: "Tiết kiệm", type: .bankSavings, currentValue: 50_000_000),
                Asset(name: "Tiền mặt", type: .cash, currentValue: 5_000_000),
            ]),
            liabilities: IdentifiedArray(uniqueElements: [
                Liability(name: "Thẻ tín dụng", type: .creditCard, principalRemaining: 2_000_000),
            ]),
            snapshots: [
                NetWorthSnapshot(
                    date: Date().addingTimeInterval(-60 * 60 * 24 * 60),
                    totalAssets: 42_000_000,
                    totalLiabilities: 3_000_000
                ),
                NetWorthSnapshot(
                    date: Date().addingTimeInterval(-60 * 60 * 24 * 30),
                    totalAssets: 50_000_000,
                    totalLiabilities: 2_500_000
                ),
            ],
            referenceDate: Date()
        )
    ) {
        WealthFeature()
    }
}
