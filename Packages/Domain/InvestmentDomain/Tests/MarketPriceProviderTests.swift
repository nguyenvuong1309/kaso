import Foundation
import Testing
@testable import InvestmentDomain

struct MarketPriceProviderTests {
    @Test("offline snapshot returns quotes for known tickers")
    func offlineSnapshotKnownTickers() async throws {
        let quotes = try await MarketPriceProvider.offlineSnapshot.fetchQuotes(["VCB", "FPT"])
        #expect(quotes.count == 2)
        let symbols = Set(quotes.map(\.symbol))
        #expect(symbols.contains("VCB"))
        #expect(symbols.contains("FPT"))
        #expect(quotes.allSatisfy { $0.source == .network })
        #expect(quotes.allSatisfy { $0.currency == "VND" })
    }

    @Test("offline snapshot ignores unknown tickers but throws when nothing matches")
    func offlineSnapshotUnknown() async {
        await #expect(throws: MarketPriceProviderError.self) {
            _ = try await MarketPriceProvider.offlineSnapshot.fetchQuotes(["DOES_NOT_EXIST"])
        }
    }

    @Test("offline snapshot normalises ticker casing")
    func offlineSnapshotCaseInsensitive() async throws {
        let quotes = try await MarketPriceProvider.offlineSnapshot.fetchQuotes(["vcb", "Fpt"])
        let symbols = Set(quotes.map(\.symbol))
        #expect(symbols == ["VCB", "FPT"])
    }

    @Test("offline snapshot quote price matches table entry")
    func priceMatchesTable() async throws {
        let quotes = try await MarketPriceProvider.offlineSnapshot.fetchQuotes(["FPT"])
        let fpt = try #require(quotes.first)
        let expected = OfflineMarketSnapshot.priceTable["FPT"]
        #expect(fpt.price == expected)
    }

    @Test("empty provider always throws unavailable")
    func emptyProviderThrows() async {
        await #expect(throws: MarketPriceProviderError.providerUnavailable) {
            _ = try await MarketPriceProvider.empty.fetchQuotes(["VCB"])
        }
    }
}
