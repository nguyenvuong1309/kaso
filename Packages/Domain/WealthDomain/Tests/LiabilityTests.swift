import Foundation
import Testing
@testable import WealthDomain

@Test("liability init applies default flags")
func liabilityInitDefaults() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B1"))
    let liability = Liability(
        id: id,
        name: "Vay tiêu dùng",
        type: .personalLoan,
        principalRemaining: 5_000_000,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 0)
    )

    #expect(liability.id == id)
    #expect(liability.name == "Vay tiêu dùng")
    #expect(liability.type == .personalLoan)
    #expect(liability.principalRemaining == 5_000_000)
    #expect(liability.note == nil)
    #expect(liability.isAutoTracked == false)
}

@Test("liability init retains all provided fields")
func liabilityInitFull() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B2"))
    let updated = Date(timeIntervalSinceReferenceDate: 300)
    let liability = Liability(
        id: id,
        name: "Thế chấp",
        type: .mortgage,
        principalRemaining: 1_200_000_000,
        note: "Ngân hàng X",
        isAutoTracked: true,
        lastUpdatedAt: updated
    )

    #expect(liability.note == "Ngân hàng X")
    #expect(liability.isAutoTracked)
    #expect(liability.lastUpdatedAt == updated)
}

@Test("liability equality distinguishes value differences")
func liabilityEquality() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B3"))
    let updated = Date(timeIntervalSinceReferenceDate: 0)
    let base = Liability(id: id, name: "L", type: .creditCard, principalRemaining: 100, lastUpdatedAt: updated)
    let same = Liability(id: id, name: "L", type: .creditCard, principalRemaining: 100, lastUpdatedAt: updated)
    let different = Liability(id: id, name: "L", type: .creditCard, principalRemaining: 300, lastUpdatedAt: updated)

    #expect(base == same)
    #expect(base != different)
}

@Test("liability round-trips through Codable")
func liabilityCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000B4"))
    let liability = Liability(
        id: id,
        name: "Vay xe",
        type: .autoLoan,
        principalRemaining: 250_000_000,
        note: "36 tháng",
        isAutoTracked: false,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 125)
    )

    let data = try JSONEncoder().encode(liability)
    let decoded = try JSONDecoder().decode(Liability.self, from: data)

    #expect(decoded == liability)
}
