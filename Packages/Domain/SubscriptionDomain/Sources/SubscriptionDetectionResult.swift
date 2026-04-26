import Foundation

public struct SubscriptionDetectionResult: Equatable, Sendable {
    public var subscriptions: [DetectedSubscription]
    public var monthlyTotal: Decimal

    public init(subscriptions: [DetectedSubscription]) {
        self.subscriptions = subscriptions
        self.monthlyTotal = subscriptions.reduce(Decimal(0)) { total, subscription in
            total + subscription.monthlyAmount
        }
    }
}
