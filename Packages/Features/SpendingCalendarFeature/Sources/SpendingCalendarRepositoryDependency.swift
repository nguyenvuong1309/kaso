import ComposableArchitecture
import Foundation
import SpendingCalendarDomain

private enum SpendingCalendarContextClientKey: DependencyKey {
    static let liveValue = SpendingCalendarContextClient.empty
    static let previewValue = SpendingCalendarContextClient.preview
    static let testValue = SpendingCalendarContextClient.empty
}

public extension SpendingCalendarContextClient {
    static let preview = SpendingCalendarContextClient(
        fetchTransactions: {
            let now = Date()
            return (0 ..< 20).map { offset in
                SpendingCalendarTransaction(
                    amount: Decimal(50_000 + offset * 30_000),
                    occurredAt: now.addingTimeInterval(-Double(offset) * 86_400),
                    label: "Sample",
                    category: "food"
                )
            }
        },
        fetchRecurringEvents: {
            [
                SpendingCalendarRecurringEvent(
                    label: "Tiền nhà",
                    amount: 8_000_000,
                    firstOccurrence: .now.addingTimeInterval(7 * 86_400),
                    intervalDays: 30,
                    category: "housing"
                ),
                SpendingCalendarRecurringEvent(
                    label: "Spotify",
                    amount: 130_000,
                    firstOccurrence: .now.addingTimeInterval(10 * 86_400),
                    intervalDays: 30,
                    category: "subscription"
                ),
            ]
        }
    )
}

public extension DependencyValues {
    var spendingCalendarContextClient: SpendingCalendarContextClient {
        get { self[SpendingCalendarContextClientKey.self] }
        set { self[SpendingCalendarContextClientKey.self] = newValue }
    }
}
