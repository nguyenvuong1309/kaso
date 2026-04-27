import Foundation
import SwiftUI
import ComposableArchitecture
import InsightDomain
import TransactionDomain

#Preview("Light") {
    BenchmarkView(store: previewStore)
}

#Preview("Dark") {
    BenchmarkView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    BenchmarkView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<BenchmarkFeature> {
    let profile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .twentyToFortyMillion
    )
    let transactions = [
        Transaction(
            amount: 3_600_000,
            kind: .expense,
            category: .food,
            occurredAt: Date()
        ),
        Transaction(
            amount: 1_200_000,
            kind: .expense,
            category: .transport,
            occurredAt: Date()
        ),
    ]

    return Store(
        initialState: BenchmarkFeature.State(
            transactions: transactions,
            profile: profile,
            report: AnonymousBenchmarkReporter.report(
                transactions: transactions,
                profile: profile,
                referenceDate: Date()
            ),
            referenceDate: Date()
        )
    ) {
        BenchmarkFeature()
    }
}
