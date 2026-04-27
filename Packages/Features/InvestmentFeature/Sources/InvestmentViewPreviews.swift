import SwiftUI
import ComposableArchitecture
import InvestmentDomain

#Preview("Investment Light") {
    InvestmentView(store: previewStore)
}

#Preview("Investment Dark") {
    InvestmentView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Investment Dynamic Type XL") {
    InvestmentView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<InvestmentFeature> {
    let holding = Holding(
        symbol: "FPT",
        name: "FPT Corp",
        assetClass: .stock,
        lots: [
            InvestmentLot(
                quantity: 100,
                costBasisPerUnit: 90_000,
                purchasedAt: Date().addingTimeInterval(-60 * 60 * 24 * 120)
            ),
        ]
    )
    let gold = Holding(
        symbol: "SJC",
        name: "Vàng SJC",
        assetClass: .gold,
        lots: [
            InvestmentLot(
                quantity: 2,
                costBasisPerUnit: 80_000_000,
                purchasedAt: Date().addingTimeInterval(-60 * 60 * 24 * 90)
            ),
        ]
    )
    return Store(
        initialState: InvestmentFeature.State(
            holdings: IdentifiedArray(uniqueElements: [holding, gold]),
            quotes: [
                PriceQuote(symbol: "FPT", price: 110_000, asOf: Date()),
                PriceQuote(symbol: "SJC", price: 88_000_000, asOf: Date()),
            ],
            targetAllocation: TargetAllocation(fractions: [.stock: 0.7, .gold: 0.3]),
            referenceDate: Date()
        )
    ) {
        InvestmentFeature()
    }
}
