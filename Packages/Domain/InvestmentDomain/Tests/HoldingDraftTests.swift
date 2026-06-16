import Foundation
import Testing
@testable import InvestmentDomain

struct HoldingDraftTests {
    @Test("default draft starts with one empty lot and stock asset class")
    func defaults() {
        let draft = HoldingDraft()
        #expect(draft.symbol.isEmpty)
        #expect(draft.name.isEmpty)
        #expect(draft.assetClass == .stock)
        #expect(draft.currency == "VND")
        #expect(draft.lots.count == 1)
        #expect(draft.note == nil)
    }

    @Test("empty lots produce lotsRequired error")
    func emptyLotsError() {
        let draft = HoldingDraft(symbol: "VNM", name: "Vinamilk", lots: [])
        #expect(draft.validationErrors().contains(.lotsRequired))
    }

    @Test("valid draft produces no errors")
    func validDraftNoErrors() throws {
        let draft = HoldingDraft(
            symbol: "VNM",
            name: "Vinamilk",
            lots: [LotDraft(quantity: 10, costBasisPerUnit: 70_000, purchasedAt: try makeDate(year: 2025, month: 1, day: 1))]
        )
        #expect(draft.validationErrors().isEmpty)
    }

    @Test("zero cost basis is allowed but negative is not")
    func zeroCostBasisAllowed() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let zero = HoldingDraft(symbol: "X", name: "X", lots: [LotDraft(quantity: 1, costBasisPerUnit: 0, purchasedAt: date)])
        #expect(zero.validationErrors().isEmpty)

        let negative = HoldingDraft(symbol: "X", name: "X", lots: [LotDraft(quantity: 1, costBasisPerUnit: -1, purchasedAt: date)])
        #expect(negative.validationErrors().contains(.lotCostBasisCannotBeNegative))
    }

    @Test("validated trims symbol/name, uppercases symbol and currency")
    func validatedTrimsAndUppercases() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let draft = HoldingDraft(
            symbol: "  vnm ",
            name: "  Vinamilk ",
            currency: " vnd ",
            lots: [LotDraft(quantity: 10, costBasisPerUnit: 70_000, purchasedAt: date)]
        )
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
        let createdAt = try makeDate(year: 2025, month: 5, day: 5)
        let holding = try draft.validated(id: id, createdAt: createdAt)

        #expect(holding.id == id)
        #expect(holding.symbol == "VNM")
        #expect(holding.name == "Vinamilk")
        #expect(holding.currency == "VND")
        #expect(holding.createdAt == createdAt)
        #expect(holding.lots.count == 1)
    }

    @Test("validated falls back to VND when currency is blank")
    func currencyFallback() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let draft = HoldingDraft(
            symbol: "X",
            name: "X",
            currency: "   ",
            lots: [LotDraft(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)]
        )
        let holding = try draft.validated()
        #expect(holding.currency == "VND")
    }

    @Test("validated throws the first validation error")
    func validatedThrows() {
        let draft = HoldingDraft(symbol: "  ", name: "Name", lots: [])
        #expect(throws: HoldingValidationError.symbolRequired) {
            _ = try draft.validated()
        }
    }

    @Test("updating preserves existing id and createdAt")
    func updatingPreservesIdentity() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let existingId = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D2"))
        let createdAt = try makeDate(year: 2024, month: 1, day: 1)
        let existing = Holding(
            id: existingId,
            symbol: "OLD",
            name: "Old",
            assetClass: .bond,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)],
            createdAt: createdAt
        )
        let draft = HoldingDraft(
            symbol: "new",
            name: "New Name",
            assetClass: .stock,
            lots: [LotDraft(quantity: 5, costBasisPerUnit: 100, purchasedAt: date)]
        )
        let updated = try draft.updating(existing: existing)

        #expect(updated.id == existingId)
        #expect(updated.createdAt == createdAt)
        #expect(updated.symbol == "NEW")
        #expect(updated.name == "New Name")
        #expect(updated.assetClass == .stock)
    }

    @Test("updating throws when draft is invalid")
    func updatingThrows() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let existing = Holding(
            symbol: "OLD",
            name: "Old",
            assetClass: .stock,
            lots: [InvestmentLot(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)]
        )
        let draft = HoldingDraft(symbol: "X", name: "X", lots: [])
        #expect(throws: HoldingValidationError.lotsRequired) {
            _ = try draft.updating(existing: existing)
        }
    }

    @Test("round-trips between holding and draft")
    func roundTripFromHolding() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let holding = Holding(
            symbol: "VNM",
            name: "Vinamilk",
            assetClass: .etf,
            currency: "USD",
            lots: [InvestmentLot(quantity: 3, costBasisPerUnit: 200, purchasedAt: date, note: "n")],
            note: "holding note"
        )
        let draft = HoldingDraft(holding: holding)
        #expect(draft.symbol == "VNM")
        #expect(draft.assetClass == .etf)
        #expect(draft.currency == "USD")
        #expect(draft.lots.count == 1)
        #expect(draft.note == "holding note")
    }

    @Test("codable round-trip preserves draft")
    func codableRoundTrip() throws {
        let date = try makeDate(year: 2025, month: 1, day: 1)
        let draft = HoldingDraft(
            symbol: "VNM",
            name: "Vinamilk",
            assetClass: .crypto,
            lots: [LotDraft(quantity: 1, costBasisPerUnit: 1, purchasedAt: date)],
            note: "x"
        )
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(HoldingDraft.self, from: data)
        #expect(decoded == draft)
    }
}
