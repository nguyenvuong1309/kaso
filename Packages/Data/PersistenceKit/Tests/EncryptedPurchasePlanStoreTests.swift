import CoolingOffDomain
import Foundation
import PersistenceKit
import Testing

@Test("purchase plan store saves and fetches encrypted plans")
func purchasePlanStoreSavesAndFetches() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("cooling-off.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let plan = PurchasePlan(
        title: "AirPods",
        amount: 6_000_000,
        category: .electronics,
        coolingPeriod: .oneWeek,
        status: .waiting,
        createdAt: Date(timeIntervalSinceReferenceDate: 0),
        availableAt: Date(timeIntervalSinceReferenceDate: 7 * 86_400)
    )
    let store = EncryptedPurchasePlanStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 19, count: 32) }
    )

    try await store.save(plan)
    let loaded = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([plan])

    #expect(loaded == [plan])
    #expect(rawData != plainData)

    try await store.delete(plan.id)
    #expect(try await store.fetchAll() == [])
}

@Test("purchase plan store persists custom policy")
func purchasePlanStorePersistsPolicy() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("cooling-off.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let policy = CoolingOffPolicy(
        thresholds: [
            CoolingOffPolicy.Threshold(minAmount: 1_000_000, period: .threeDays),
        ],
        defaultPeriod: .oneDay
    )
    let store = EncryptedPurchasePlanStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 23, count: 32) }
    )

    try await store.savePolicy(policy)
    #expect(try await store.loadPolicy() == policy)
}
