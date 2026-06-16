import Foundation
import Testing
@testable import WealthDomain

@Test("asset init applies default flags")
func assetInitDefaults() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1"))
    let asset = Asset(
        id: id,
        name: "Tiền mặt",
        type: .cash,
        currentValue: 1_000_000,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 0)
    )

    #expect(asset.id == id)
    #expect(asset.name == "Tiền mặt")
    #expect(asset.type == .cash)
    #expect(asset.currentValue == 1_000_000)
    #expect(asset.acquiredAt == nil)
    #expect(asset.note == nil)
    #expect(asset.isAutoTracked == false)
}

@Test("asset init retains all provided fields")
func assetInitFull() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A2"))
    let acquired = Date(timeIntervalSinceReferenceDate: 100)
    let updated = Date(timeIntervalSinceReferenceDate: 200)
    let asset = Asset(
        id: id,
        name: "Cổ phiếu",
        type: .investment,
        currentValue: 30_000_000,
        acquiredAt: acquired,
        note: "VND",
        isAutoTracked: true,
        lastUpdatedAt: updated
    )

    #expect(asset.acquiredAt == acquired)
    #expect(asset.note == "VND")
    #expect(asset.isAutoTracked)
    #expect(asset.lastUpdatedAt == updated)
}

@Test("asset equality distinguishes value differences")
func assetEquality() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A3"))
    let updated = Date(timeIntervalSinceReferenceDate: 0)
    let base = Asset(id: id, name: "A", type: .cash, currentValue: 100, lastUpdatedAt: updated)
    let same = Asset(id: id, name: "A", type: .cash, currentValue: 100, lastUpdatedAt: updated)
    let different = Asset(id: id, name: "A", type: .cash, currentValue: 200, lastUpdatedAt: updated)

    #expect(base == same)
    #expect(base != different)
}

@Test("asset round-trips through Codable")
func assetCodableRoundTrip() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A4"))
    let asset = Asset(
        id: id,
        name: "Nhà",
        type: .realEstate,
        currentValue: 2_000_000_000,
        acquiredAt: Date(timeIntervalSinceReferenceDate: 50),
        note: "Quận 1",
        isAutoTracked: false,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 75)
    )

    let data = try JSONEncoder().encode(asset)
    let decoded = try JSONDecoder().decode(Asset.self, from: data)

    #expect(decoded == asset)
}

@Test("asset sample uses defaults and accepts overrides")
func assetSample() throws {
    let defaultSample = Asset.sample()
    #expect(defaultSample.name == "Tài khoản tiết kiệm")
    #expect(defaultSample.type == .bankSavings)
    #expect(defaultSample.currentValue == 50_000_000)

    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A5"))
    let custom = Asset.sample(id: id, name: "Ví", type: .cash, currentValue: 1_234)
    #expect(custom.id == id)
    #expect(custom.name == "Ví")
    #expect(custom.type == .cash)
    #expect(custom.currentValue == 1_234)
}
