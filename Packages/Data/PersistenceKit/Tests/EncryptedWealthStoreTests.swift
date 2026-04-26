import Foundation
import PersistenceKit
import Testing
import WealthDomain

@Test("saves fetches and deletes assets encrypted")
func savesFetchesAndDeletesAssetsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("assets.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let asset = Asset(
        name: "Tiết kiệm",
        type: .bankSavings,
        currentValue: 50_000_000,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let store = EncryptedAssetStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 31, count: 32) }
    )

    try await store.save(asset)

    let loadedAssets = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([asset])

    #expect(loadedAssets == [asset])
    #expect(rawData != plainData)

    try await store.delete(asset.id)
    #expect(try await store.fetchAll() == [])
}

@Test("saves fetches and deletes liabilities encrypted")
func savesFetchesAndDeletesLiabilitiesEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("liabilities.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let liability = Liability(
        name: "Vay mua nhà",
        type: .mortgage,
        principalRemaining: 800_000_000,
        lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let store = EncryptedLiabilityStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 37, count: 32) }
    )

    try await store.save(liability)

    let loadedLiabilities = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([liability])

    #expect(loadedLiabilities == [liability])
    #expect(rawData != plainData)

    try await store.delete(liability.id)
    #expect(try await store.fetchAll() == [])
}

@Test("saves and prunes net worth snapshots encrypted")
func savesAndPrunesNetWorthSnapshotsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("net-worth.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let oldSnapshot = NetWorthSnapshot(
        date: Date(timeIntervalSinceReferenceDate: 100),
        totalAssets: 30_000_000,
        totalLiabilities: 2_000_000
    )
    let newSnapshot = NetWorthSnapshot(
        date: Date(timeIntervalSinceReferenceDate: 200),
        totalAssets: 40_000_000,
        totalLiabilities: 1_000_000
    )
    let store = EncryptedNetWorthSnapshotStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 41, count: 32) }
    )

    try await store.save(newSnapshot)
    try await store.save(oldSnapshot)

    let loadedSnapshots = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([oldSnapshot, newSnapshot])

    #expect(loadedSnapshots == [oldSnapshot, newSnapshot])
    #expect(rawData != plainData)

    try await store.prune(before: Date(timeIntervalSinceReferenceDate: 150))
    #expect(try await store.fetchAll() == [newSnapshot])
}
