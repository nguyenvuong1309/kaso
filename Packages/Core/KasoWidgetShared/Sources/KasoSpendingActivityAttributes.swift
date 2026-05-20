import Foundation
#if os(iOS)
import ActivityKit

/// Live Activity describing in-progress spending throughout the day.
///
/// The main app starts an activity when there's at least one expense today
/// and updates `ContentState` after each transaction. Dynamic Island + Lock
/// Screen views in the widget extension render the latest content state.
public struct KasoSpendingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var totalSpentToday: Decimal
        public var budgetRemaining: Decimal
        public var transactionCount: Int

        public init(totalSpentToday: Decimal, budgetRemaining: Decimal, transactionCount: Int) {
            self.totalSpentToday = totalSpentToday
            self.budgetRemaining = budgetRemaining
            self.transactionCount = transactionCount
        }
    }

    public var sessionLabel: String
    public var currencyCode: String

    public init(sessionLabel: String, currencyCode: String) {
        self.sessionLabel = sessionLabel
        self.currencyCode = currencyCode
    }
}
#endif
