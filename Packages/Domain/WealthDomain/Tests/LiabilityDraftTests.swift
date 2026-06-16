import Foundation
import Testing
@testable import WealthDomain

@Test("liability draft default init starts empty and valued at zero")
func liabilityDraftDefaultInit() {
    let draft = LiabilityDraft()
    #expect(draft.name.isEmpty)
    #expect(draft.type == .personalLoan)
    #expect(draft.principalRemaining == 0)
    #expect(draft.note == nil)
}

@Test("liability draft init from liability copies editable fields")
func liabilityDraftFromLiability() {
    let liability = Liability(
        name: "Thẻ Visa",
        type: .creditCard,
        principalRemaining: 8_000_000,
        note: "trả góp",
        isAutoTracked: true
    )

    let draft = LiabilityDraft(liability: liability)

    #expect(draft.name == "Thẻ Visa")
    #expect(draft.type == .creditCard)
    #expect(draft.principalRemaining == 8_000_000)
    #expect(draft.note == "trả góp")
}

@Test("liability draft reports no errors when valid")
func liabilityDraftNoErrors() {
    let draft = LiabilityDraft(name: "Hợp lệ", type: .bnpl, principalRemaining: 0)
    #expect(draft.validationErrors().isEmpty)
}

@Test("liability draft validated trims name and empties blank note")
func liabilityDraftValidated() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000D1"))
    let draft = LiabilityDraft(
        name: "  Vay sinh viên  ",
        type: .studentLoan,
        principalRemaining: 40_000_000,
        note: "   "
    )

    let liability = try draft.validated(id: id, lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 0))

    #expect(liability.id == id)
    #expect(liability.name == "Vay sinh viên")
    #expect(liability.type == .studentLoan)
    #expect(liability.principalRemaining == 40_000_000)
    #expect(liability.note == nil)
    #expect(liability.isAutoTracked == false)
}

@Test("liability draft validated throws on negative principal")
func liabilityDraftValidatedThrows() throws {
    let draft = LiabilityDraft(name: "Hợp lệ", type: .other, principalRemaining: -5)

    #expect(throws: LiabilityValidationError.principalCannotBeNegative) {
        _ = try draft.validated()
    }
}

@Test("liability draft updating throws on invalid input")
func liabilityDraftUpdatingThrows() throws {
    let existing = Liability(name: "Cũ", type: .other, principalRemaining: 0)
    let draft = LiabilityDraft(name: "   ", type: .other, principalRemaining: 0)

    #expect(throws: LiabilityValidationError.nameRequired) {
        _ = try draft.updating(existing: existing)
    }
}

@Test("liability validation error round-trips through Codable")
func liabilityValidationErrorCodable() throws {
    let data = try JSONEncoder().encode(LiabilityValidationError.nameRequired)
    let decoded = try JSONDecoder().decode(LiabilityValidationError.self, from: data)
    #expect(decoded == .nameRequired)
}
