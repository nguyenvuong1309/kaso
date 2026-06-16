import Foundation
import Testing
@testable import InvestmentDomain

struct HoldingRepositoryTests {
    @Test("empty holding repository fetches an empty list")
    func emptyHoldingFetch() async throws {
        let holdings = try await HoldingRepository.empty.fetchAll()
        #expect(holdings.isEmpty)
    }

    @Test("empty holding repository save and delete are no-ops")
    func emptyHoldingMutations() async throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000E1"))
        let holding = Holding(
            symbol: "VNM",
            name: "Vinamilk",
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 1, purchasedAt: try makeDate(year: 2025, month: 1, day: 1))]
        )
        try await HoldingRepository.empty.save(holding)
        try await HoldingRepository.empty.delete(id)
    }

    @Test("empty price quote repository fetches an empty list")
    func emptyQuoteFetch() async throws {
        let quotes = try await PriceQuoteRepository.empty.fetchAll()
        #expect(quotes.isEmpty)
    }

    @Test("empty price quote repository save and saveMany are no-ops")
    func emptyQuoteMutations() async throws {
        let quote = PriceQuote(symbol: "VNM", price: 75_000, asOf: try makeDate(year: 2025, month: 6, day: 1))
        try await PriceQuoteRepository.empty.save(quote)
        try await PriceQuoteRepository.empty.saveMany([quote])
    }

    @Test("custom repository routes through its injected closures")
    func customHoldingRepository() async throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let stored = Holding(
            symbol: "FPT",
            name: "FPT",
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)]
        )
        let repository = HoldingRepository(
            fetchAll: { [stored] },
            save: { _ in },
            delete: { _ in }
        )
        let result = try await repository.fetchAll()
        #expect(result == [stored])
    }
}
