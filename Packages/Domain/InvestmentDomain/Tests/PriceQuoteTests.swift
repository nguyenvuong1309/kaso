import Foundation
import Testing
@testable import InvestmentDomain

struct PriceQuoteTests {
    @Test("default source is manual and currency is VND")
    func defaults() throws {
        let quote = PriceQuote(symbol: "vnm", price: 75_000, asOf: try makeDate(year: 2025, month: 6, day: 1))
        #expect(quote.source == .manual)
        #expect(quote.currency == "VND")
    }

    @Test("id is the uppercased symbol")
    func idIsUppercased() throws {
        let quote = PriceQuote(symbol: "fpt", price: 1, asOf: try makeDate(year: 2025, month: 6, day: 1))
        #expect(quote.id == "FPT")
    }

    @Test("explicit source and currency are preserved")
    func explicitFields() throws {
        let quote = PriceQuote(
            symbol: "BTC",
            price: 1_000_000,
            asOf: try makeDate(year: 2025, month: 6, day: 1),
            source: .network,
            currency: "USD"
        )
        #expect(quote.source == .network)
        #expect(quote.currency == "USD")
    }

    @Test("codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let quote = PriceQuote(
            symbol: "VCB",
            price: 91_000,
            asOf: try makeDate(year: 2025, month: 4, day: 23),
            source: .network,
            currency: "VND"
        )
        let data = try JSONEncoder().encode(quote)
        let decoded = try JSONDecoder().decode(PriceQuote.self, from: data)
        #expect(decoded == quote)
    }

    @Test("equatable distinguishes different prices")
    func equatable() throws {
        let date = try makeDate(year: 2025, month: 6, day: 1)
        let a = PriceQuote(symbol: "X", price: 1, asOf: date)
        let b = PriceQuote(symbol: "X", price: 2, asOf: date)
        #expect(a != b)
    }

    @Test("price source raw values are stable")
    func priceSourceRawValues() {
        #expect(PriceSource.manual.rawValue == "manual")
        #expect(PriceSource.network.rawValue == "network")
    }

    @Test("price source codable round-trip")
    func priceSourceCodable() throws {
        for source in [PriceSource.manual, .network] {
            let data = try JSONEncoder().encode(source)
            let decoded = try JSONDecoder().decode(PriceSource.self, from: data)
            #expect(decoded == source)
        }
    }
}
