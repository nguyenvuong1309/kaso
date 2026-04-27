import Foundation
import ComposableArchitecture
import TransactionDomain

public struct FinancialAssistantContextClient: Sendable {
    public var loadTransactions: @Sendable () async throws -> [Transaction]

    public init(
        loadTransactions: @escaping @Sendable () async throws -> [Transaction]
    ) {
        self.loadTransactions = loadTransactions
    }
}

public extension FinancialAssistantContextClient {
    static let empty = FinancialAssistantContextClient(loadTransactions: { [] })

    static let preview = FinancialAssistantContextClient(
        loadTransactions: {
            [
                Transaction(
                    amount: 18_000_000,
                    kind: .income,
                    category: .salary,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 3_200_000,
                    kind: .expense,
                    category: .food,
                    occurredAt: Date()
                ),
                Transaction(
                    amount: 1_100_000,
                    kind: .expense,
                    category: .transport,
                    occurredAt: Date().addingTimeInterval(-86_400)
                ),
            ]
        }
    )
}

private enum FinancialAssistantContextClientKey: DependencyKey {
    static let liveValue = FinancialAssistantContextClient.empty
    static let previewValue = FinancialAssistantContextClient.preview
    static let testValue = FinancialAssistantContextClient.empty
}

public extension DependencyValues {
    var financialAssistantContextClient: FinancialAssistantContextClient {
        get { self[FinancialAssistantContextClientKey.self] }
        set { self[FinancialAssistantContextClientKey.self] = newValue }
    }
}
