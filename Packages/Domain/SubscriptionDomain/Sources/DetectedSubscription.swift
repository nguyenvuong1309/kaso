import Foundation
import TransactionDomain

public struct DetectedSubscription: Identifiable, Codable, Equatable, Sendable {
    public var id: String {
        "\(merchant.normalizedKey):\(interval.rawValue)"
    }

    public var name: String {
        merchant.name
    }

    public var merchant: SubscriptionMerchant
    public var category: TransactionCategory
    public var interval: SubscriptionInterval
    public var averageAmount: Decimal
    public var monthlyAmount: Decimal
    public var lastBillingDate: Date
    public var nextBillingDate: Date
    public var transactionIDs: [Transaction.ID]
    public var confidence: Double

    public init(
        merchant: SubscriptionMerchant,
        category: TransactionCategory,
        interval: SubscriptionInterval,
        averageAmount: Decimal,
        monthlyAmount: Decimal,
        lastBillingDate: Date,
        nextBillingDate: Date,
        transactionIDs: [Transaction.ID],
        confidence: Double
    ) {
        self.merchant = merchant
        self.category = category
        self.interval = interval
        self.averageAmount = averageAmount
        self.monthlyAmount = monthlyAmount
        self.lastBillingDate = lastBillingDate
        self.nextBillingDate = nextBillingDate
        self.transactionIDs = transactionIDs
        self.confidence = confidence
    }
}
