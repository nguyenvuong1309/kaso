import Foundation
import Testing
@testable import InvestmentDomain

struct HoldingTests {
    private func lot(_ quantity: Decimal, _ cost: Decimal, day: Int) throws -> InvestmentLot {
        InvestmentLot(quantity: quantity, costBasisPerUnit: cost, purchasedAt: try makeDate(year: 2025, month: 1, day: day))
    }

    @Test("total quantity sums every lot quantity")
    func totalQuantity() throws {
        let holding = Holding(
            symbol: "FPT",
            name: "FPT",
            assetClass: .stock,
            lots: [try lot(50, 90_000, day: 1), try lot(50, 100_000, day: 2)]
        )
        #expect(holding.totalQuantity == 100)
    }

    @Test("total cost sums every lot total cost")
    func totalCost() throws {
        let holding = Holding(
            symbol: "FPT",
            name: "FPT",
            assetClass: .stock,
            lots: [try lot(50, 90_000, day: 1), try lot(50, 100_000, day: 2)]
        )
        #expect(holding.totalCost == 50 * 90_000 + 50 * 100_000)
    }

    @Test("average cost per unit weights by quantity")
    func averageCostPerUnit() throws {
        let holding = Holding(
            symbol: "FPT",
            name: "FPT",
            assetClass: .stock,
            lots: [try lot(50, 90_000, day: 1), try lot(50, 100_000, day: 2)]
        )
        #expect(holding.averageCostPerUnit == 95_000)
    }

    @Test("average cost per unit is zero when there are no lots")
    func averageCostNoLots() {
        let holding = Holding(symbol: "X", name: "X", assetClass: .stock, lots: [])
        #expect(holding.totalQuantity == 0)
        #expect(holding.totalCost == 0)
        #expect(holding.averageCostPerUnit == 0)
    }

    @Test("average cost per unit is zero when total quantity is zero")
    func averageCostZeroQuantity() throws {
        let holding = Holding(
            symbol: "X",
            name: "X",
            assetClass: .stock,
            lots: [try lot(0, 50_000, day: 1)]
        )
        #expect(holding.averageCostPerUnit == 0)
    }

    @Test("default currency is VND and note is nil")
    func defaults() {
        let holding = Holding(symbol: "X", name: "X", assetClass: .stock)
        #expect(holding.currency == "VND")
        #expect(holding.note == nil)
        #expect(holding.lots.isEmpty)
    }

    @Test("codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let holding = Holding(
            id: id,
            symbol: "VNM",
            name: "Vinamilk",
            assetClass: .stock,
            currency: "VND",
            lots: [try lot(10, 70_000, day: 5)],
            note: "core position",
            createdAt: try makeDate(year: 2025, month: 2, day: 1)
        )
        let data = try JSONEncoder().encode(holding)
        let decoded = try JSONDecoder().decode(Holding.self, from: data)
        #expect(decoded == holding)
    }
}
