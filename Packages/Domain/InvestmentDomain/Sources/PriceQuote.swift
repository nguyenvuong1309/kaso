import Foundation

public enum PriceSource: String, Codable, Equatable, Sendable {
    case manual
    case network
}

public struct PriceQuote: Identifiable, Codable, Equatable, Sendable {
    public var symbol: String
    public var price: Decimal
    public var asOf: Date
    public var source: PriceSource
    public var currency: String

    public init(
        symbol: String,
        price: Decimal,
        asOf: Date,
        source: PriceSource = .manual,
        currency: String = "VND"
    ) {
        self.symbol = symbol
        self.price = price
        self.asOf = asOf
        self.source = source
        self.currency = currency
    }

    public var id: String {
        symbol.uppercased()
    }
}
