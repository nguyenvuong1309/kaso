import Foundation
import Testing
@testable import InvestmentDomain

struct LotDraftTests {
    @Test("default draft has zeroed quantity, cost and nil note")
    func defaults() {
        let draft = LotDraft()
        #expect(draft.quantity == 0)
        #expect(draft.costBasisPerUnit == 0)
        #expect(draft.note == nil)
    }

    @Test("toLot preserves id, quantity, cost and purchase date")
    func toLotPreservesFields() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000F1"))
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let draft = LotDraft(id: id, quantity: 12, costBasisPerUnit: 50_000, purchasedAt: date, note: "buy")
        let lot = draft.toLot()
        #expect(lot.id == id)
        #expect(lot.quantity == 12)
        #expect(lot.costBasisPerUnit == 50_000)
        #expect(lot.purchasedAt == date)
        #expect(lot.note == "buy")
    }

    @Test("toLot trims whitespace from note")
    func toLotTrimsNote() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let draft = LotDraft(quantity: 1, costBasisPerUnit: 1, purchasedAt: date, note: "  hello  ")
        #expect(draft.toLot().note == "hello")
    }

    @Test("toLot converts a blank note to nil")
    func toLotBlankNoteNil() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let draft = LotDraft(quantity: 1, costBasisPerUnit: 1, purchasedAt: date, note: "   ")
        #expect(draft.toLot().note == nil)
    }

    @Test("toLot keeps nil note as nil")
    func toLotNilNote() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let draft = LotDraft(quantity: 1, costBasisPerUnit: 1, purchasedAt: date, note: nil)
        #expect(draft.toLot().note == nil)
    }

    @Test("init(lot:) copies all lot fields")
    func initFromLot() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000F2"))
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(id: id, quantity: 5, costBasisPerUnit: 200, purchasedAt: date, note: "n")
        let draft = LotDraft(lot: lot)
        #expect(draft.id == id)
        #expect(draft.quantity == 5)
        #expect(draft.costBasisPerUnit == 200)
        #expect(draft.purchasedAt == date)
        #expect(draft.note == "n")
    }

    @Test("lot to draft and back is round-trippable")
    func roundTrip() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000F3"))
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let lot = InvestmentLot(id: id, quantity: 7, costBasisPerUnit: 333, purchasedAt: date, note: "keep")
        let restored = LotDraft(lot: lot).toLot()
        #expect(restored == lot)
    }

    @Test("codable round-trip preserves draft")
    func codableRoundTrip() throws {
        let date = try makeDate(year: 2025, month: 3, day: 10)
        let draft = LotDraft(quantity: 3, costBasisPerUnit: 99, purchasedAt: date, note: "x")
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(LotDraft.self, from: data)
        #expect(decoded == draft)
    }
}
