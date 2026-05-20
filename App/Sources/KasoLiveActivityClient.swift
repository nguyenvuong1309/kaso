import ActivityKit
import Foundation
import KasoWidgetShared

/// Manages the lifecycle of the spending Live Activity. The app calls
/// `apply(snapshot:sessionLabel:)` every time the widget snapshot refreshes
/// (on launch + after each save) — this class decides whether to start, update
/// or end the activity based on whether the user has spending today.
@available(iOS 16.2, *)
@MainActor
final class KasoLiveActivityClient {
    static let shared = KasoLiveActivityClient()

    private var activity: Activity<KasoSpendingActivityAttributes>?

    private init() {}

    func apply(snapshot: WidgetSnapshot, sessionLabel: String) async {
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else { return }

        let hasSpendingToday = snapshot.transactionCountToday > 0
        let contentState = KasoSpendingActivityAttributes.ContentState(
            totalSpentToday: snapshot.totalSpentToday,
            budgetRemaining: snapshot.budgetRemaining,
            transactionCount: snapshot.transactionCountToday
        )

        if hasSpendingToday {
            if let existing = activity {
                await existing.update(using: contentState)
            } else {
                let attributes = KasoSpendingActivityAttributes(
                    sessionLabel: sessionLabel,
                    currencyCode: snapshot.currencyCode
                )
                do {
                    activity = try Activity<KasoSpendingActivityAttributes>.request(
                        attributes: attributes,
                        contentState: contentState,
                        pushType: nil
                    )
                } catch {
                    // Live Activity request can fail when the device is in low
                    // power mode or already at the per-app activity limit. We
                    // silently skip — next refresh will retry.
                    activity = nil
                }
            }
        } else if let existing = activity {
            await existing.end(using: contentState, dismissalPolicy: .immediate)
            activity = nil
        }
    }

    func endIfNeeded() async {
        guard let existing = activity else { return }
        await existing.end(dismissalPolicy: .immediate)
        activity = nil
    }
}
