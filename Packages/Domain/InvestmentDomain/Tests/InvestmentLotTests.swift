import Foundation
import Testing
@testable import InvestmentDomain

struct InvestmentLotTests {
    @Test("total cost is quantity times cost basis per unit")
    func totalCost() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(quantity: 100, costBasisPerUnit: 70_000, purchasedAt: date)
        #expect(lot.totalCost == 7_000_000)
    }

    @Test("total cost handles fractional quantity")
    func fractionalTotalCost() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(quantity: Decimal(string: "1.5") ?? 0, costBasisPerUnit: 1_000_000, purchasedAt: date)
        #expect(lot.totalCost == 1_500_000)
    }

    @Test("total cost is zero when quantity is zero")
    func zeroQuantity() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(quantity: 0, costBasisPerUnit: 50_000, purchasedAt: date)
        #expect(lot.totalCost == 0)
    }

    @Test("default initializer leaves note nil")
    func defaultNote() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)
        #expect(lot.note == nil)
    }

    @Test("id is preserved when passed explicitly")
    func explicitId() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
        let lot = InvestmentLot(id: id, quantity: 1, costBasisPerUnit: 1, purchasedAt: date)
        #expect(lot.id == id)
    }

    @Test("codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B2"))
        let lot = InvestmentLot(
            id: id,
            quantity: 25,
            costBasisPerUnit: 12_345,
            purchasedAt: date,
            note: "first buy"
        )
        let data = try JSONEncoder().encode(lot)
        let decoded = try JSONDecoder().decode(InvestmentLot.self, from: data)
        #expect(decoded == lot)
    }

    @Test("equatable distinguishes different quantities")
    func equatable() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B3"))
        let a = InvestmentLot(id: id, quantity: 1, costBasisPerUnit: 1, purchasedAt: date)
        let b = InvestmentLot(id: id, quantity: 2, costBasisPerUnit: 1, purchasedAt: date)
        #expect(a != b)
    }
}
