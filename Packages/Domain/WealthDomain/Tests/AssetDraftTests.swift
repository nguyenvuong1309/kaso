import Foundation
import Testing
@testable import WealthDomain

@Test("asset draft default init starts empty and valued at zero")
func assetDraftDefaultInit() {
    let draft = AssetDraft()
    #expect(draft.name.isEmpty)
    #expect(draft.type == .bankSavings)
    #expect(draft.currentValue == 0)
    #expect(draft.acquiredAt == nil)
    #expect(draft.note == nil)
}

@Test("asset draft init from asset copies editable fields")
func assetDraftFromAsset() throws {
    let acquired = Date(timeIntervalSinceReferenceDate: 10)
    let asset = Asset(
        name: "Vàng",
        type: .other,
        currentValue: 7_000_000,
        acquiredAt: acquired,
        note: "SJC",
        isAutoTracked: true
    )

    let draft = AssetDraft(asset: asset)

    #expect(draft.name == "Vàng")
    #expect(draft.type == .other)
    #expect(draft.currentValue == 7_000_000)
    #expect(draft.acquiredAt == acquired)
    #expect(draft.note == "SJC")
}

@Test("asset draft reports no errors when valid")
func assetDraftNoErrors() {
    let draft = AssetDraft(name: "Hợp lệ", type: .cash, currentValue: 0)
    #expect(draft.validationErrors().isEmpty)
}

@Test("asset draft validated with empty note returns nil note")
func assetDraftValidatedEmptyNote() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
    let draft = AssetDraft(name: "Tiền", type: .cash, currentValue: 500, note: "    ")

    let asset = try draft.validated(id: id, lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 0))

    #expect(asset.note == nil)
}

@Test("asset draft updating preserves id, auto-tracking and trims note")
func assetDraftUpdatingPreservesIdentity() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000C2"))
    let existing = Asset(
        id: id,
        name: "Cũ",
        type: .bankSavings,
        currentValue: 10_000_000,
        isAutoTracked: true
    )
    let draft = AssetDraft(name: "  Mới  ", type: .investment, currentValue: 12_000_000, note: "  ghi chú  ")

    let updated = try draft.updating(existing: existing, lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 5))

    #expect(updated.id == id)
    #expect(updated.name == "Mới")
    #expect(updated.type == .investment)
    #expect(updated.currentValue == 12_000_000)
    #expect(updated.note == "ghi chú")
    #expect(updated.isAutoTracked == true)
}

@Test("asset draft updating throws on invalid input")
func assetDraftUpdatingThrows() throws {
    let existing = Asset(name: "Cũ", type: .cash, currentValue: 0)
    let draft = AssetDraft(name: "", type: .cash, currentValue: -1)

    #expect(throws: AssetValidationError.nameRequired) {
        _ = try draft.updating(existing: existing)
    }
}

@Test("asset validation error round-trips through Codable")
func assetValidationErrorCodable() throws {
    let data = try JSONEncoder().encode(AssetValidationError.currentValueCannotBeNegative)
    let decoded = try JSONDecoder().decode(AssetValidationError.self, from: data)
    #expect(decoded == .currentValueCannotBeNegative)
}
