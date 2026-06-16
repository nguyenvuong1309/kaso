import Foundation
import Testing
import TransactionDomain
@testable import SubscriptionDomain

@Test("monthly total is zero for an empty result")
func monthlyTotalEmpty() {
    let result = SubscriptionDetectionResult(subscriptions: [])
    #expect(result.subscriptions.isEmpty)
    #expect(result.monthlyTotal == 0)
}

@Test("monthly total sums monthly amounts across subscriptions")
func monthlyTotalSumsAmounts() {
    let result = SubscriptionDetectionResult(subscriptions: [
        makeSubscription(normalizedKey: "note:a", monthlyAmount: 100_000),
        makeSubscription(normalizedKey: "note:b", monthlyAmount: 250_000),
        makeSubscription(normalizedKey: "note:c", monthlyAmount: 50_000),
    ])
    #expect(result.monthlyTotal == 400_000)
}

@Test("monthly total preserves fractional decimal amounts")
func monthlyTotalPreservesFractions() {
    let result = SubscriptionDetectionResult(subscriptions: [
        makeSubscription(normalizedKey: "note:a", monthlyAmount: Decimal(string: "100.50") ?? 0),
        makeSubscription(normalizedKey: "note:b", monthlyAmount: Decimal(string: "0.25") ?? 0),
    ])
    #expect(result.monthlyTotal == Decimal(string: "100.75"))
}

@Test("result is equatable")
func resultEquatable() {
    let subscriptions = [makeSubscription(normalizedKey: "note:a", monthlyAmount: 100_000)]
    #expect(SubscriptionDetectionResult(subscriptions: subscriptions) == SubscriptionDetectionResult(subscriptions: subscriptions))
}

private func makeSubscription(
    normalizedKey: String,
    monthlyAmount: Decimal
) -> DetectedSubscription {
    DetectedSubscription(
        merchant: SubscriptionMerchant(name: "Merchant", normalizedKey: normalizedKey, source: .note),
        category: .entertainment,
        interval: .monthly,
        averageAmount: monthlyAmount,
        monthlyAmount: monthlyAmount,
        lastBillingDate: Date(timeIntervalSince1970: 0),
        nextBillingDate: Date(timeIntervalSince1970: 2_592_000),
        transactionIDs: [],
        confidence: 1
    )
}
