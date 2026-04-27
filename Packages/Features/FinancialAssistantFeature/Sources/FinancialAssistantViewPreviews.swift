import Foundation
import SwiftUI
import ComposableArchitecture
import InsightDomain
import TransactionDomain

#Preview("Light") {
    FinancialAssistantView(store: previewStore)
}

#Preview("Dark") {
    FinancialAssistantView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    FinancialAssistantView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<FinancialAssistantFeature> {
    let answer = FinancialAssistantAnswer(
        intent: .monthStatus,
        risk: .positive,
        confidence: 0.9,
        facts: [
            FinancialAssistantFact(kind: .income, amount: 18_000_000),
            FinancialAssistantFact(kind: .expense, amount: 4_300_000),
            FinancialAssistantFact(kind: .balance, amount: 13_700_000),
            FinancialAssistantFact(kind: .projectedBalance, amount: 9_200_000),
        ]
    )

    return Store(
        initialState: FinancialAssistantFeature.State(
            messages: [
                FinancialAssistantMessage(
                    id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                    role: .user,
                    text: "Tháng này tôi còn bao nhiêu tiền?"
                ),
                FinancialAssistantMessage(
                    id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
                    role: .assistant,
                    answer: answer
                ),
            ]
        )
    ) {
        FinancialAssistantFeature()
    }
}
