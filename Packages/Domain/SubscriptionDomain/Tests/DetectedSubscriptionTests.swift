import Foundation
import Testing
import TransactionDomain
@testable import SubscriptionDomain

@Test("id combines normalized merchant key and interval raw value")
func idCombinesMerchantKeyAndInterval() {
    let subscription = makeSubscription(normalizedKey: "note:netflix", interval: .monthly)
    #expect(subscription.id == "note:netflix:monthly")
}

@Test("id changes when interval differs for the same merchant")
func idChangesWithInterval() {
    let monthly = makeSubscription(normalizedKey: "note:netflix", interval: .monthly)
    let yearly = makeSubscription(normalizedKey: "note:netflix", interval: .yearly)
    #expect(monthly.id != yearly.id)
    #expect(yearly.id == "note:netflix:yearly")
}

@Test("name forwards the merchant name")
func nameForwardsMerchantName() {
    let subscription = makeSubscription(merchantName: "Spotify", normalizedKey: "note:spotify", interval: .monthly)
    #expect(subscription.name == "Spotify")
}

@Test("detected subscription round-trips through Codable")
func detectedSubscriptionCodableRoundTrip() throws {
    let subscription = makeSubscription(normalizedKey: "note:netflix", interval: .monthly)
    let encoded = try JSONEncoder().encode(subscription)
    let decoded = try JSONDecoder().decode(DetectedSubscription.self, from: encoded)
    #expect(decoded == subscription)
    #expect(decoded.id == subscription.id)
}

@Test("equatable distinguishes differing amounts")
func equatableDistinguishesAmounts() {
    let base = makeSubscription(normalizedKey: "note:netflix", interval: .monthly)
    var other = base
    other.monthlyAmount = 999_999
    #expect(base != other)
}

private func makeSubscription(
    merchantName: String = "Netflix",
    normalizedKey: String,
    interval: SubscriptionInterval
) -> DetectedSubscription {
    DetectedSubscription(
        merchant: SubscriptionMerchant(name: merchantName, normalizedKey: normalizedKey, source: .note),
        category: .entertainment,
        interval: interval,
        averageAmount: 260_000,
        monthlyAmount: 260_000,
        lastBillingDate: Date(timeIntervalSince1970: 0),
        nextBillingDate: Date(timeIntervalSince1970: 2_592_000),
        transactionIDs: [],
        confidence: 1
    )
}
