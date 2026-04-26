import Foundation

public struct ReceiptOCRResult: Equatable, Sendable {
    public var merchantName: String?
    public var amount: Decimal?
    public var occurredAt: Date?
    public var rawText: String

    public init(
        merchantName: String? = nil,
        amount: Decimal? = nil,
        occurredAt: Date? = nil,
        rawText: String = ""
    ) {
        self.merchantName = merchantName
        self.amount = amount
        self.occurredAt = occurredAt
        self.rawText = rawText
    }
}
