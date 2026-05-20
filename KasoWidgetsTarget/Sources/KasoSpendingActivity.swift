import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

/// Live Activity describing in-progress spending throughout the day.
///
/// The main app starts an activity at the start of a session and updates
/// `ContentState` after each transaction. Dynamic Island + Lock Screen views
/// render the latest content state.
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

@available(iOS 16.2, *)
struct KasoSpendingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KasoSpendingActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                Text(context.attributes.sessionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(format(context.state.totalSpentToday, code: context.attributes.currencyCode))
                    .font(.title2)
                    .fontWeight(.semibold)
                HStack {
                    Image(systemName: "wallet.pass")
                    Text(format(context.state.budgetRemaining, code: context.attributes.currencyCode))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.6))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(format(context.state.totalSpentToday, code: context.attributes.currencyCode))
                    } icon: {
                        Image(systemName: "creditcard")
                    }
                    .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label {
                        Text(format(context.state.budgetRemaining, code: context.attributes.currencyCode))
                    } icon: {
                        Image(systemName: "wallet.pass")
                    }
                    .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.sessionLabel)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.transactionCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "creditcard")
            } compactTrailing: {
                Text(format(context.state.totalSpentToday, code: context.attributes.currencyCode))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "creditcard")
            }
        }
    }

    private func format(_ amount: Decimal, code: String) -> String {
        amount.formatted(.currency(code: code).presentation(.narrow))
    }
}
