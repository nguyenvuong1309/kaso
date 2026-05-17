import Foundation
import GuiltFreeBudgetDomain
import PersistenceKit
import Testing

@Test("guilt-free store persists configuration encrypted")
func guiltFreeStorePersistsConfiguration() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("guilt-free-budget.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let config = GuiltFreeBudgetConfiguration(
        monthlyIncome: 25_000_000,
        monthlySavingsTarget: 5_000_000,
        emergencyFundMonthlyContribution: 1_000_000,
        fixedCosts: [
            GuiltFreeFixedCost(name: "Tiền nhà", amount: 8_000_000, kind: .housing),
        ],
        updatedAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let store = EncryptedGuiltFreeBudgetConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 17, count: 32) }
    )

    try await store.save(config)
    let loaded = try await store.load()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode(config)

    #expect(loaded == config)
    #expect(rawData != plainData)
}

@Test("guilt-free store returns empty configuration when file missing")
func guiltFreeStoreReturnsEmptyWhenMissing() async throws {
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("missing-\(UUID().uuidString).kasoenc")
    let store = EncryptedGuiltFreeBudgetConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 17, count: 32) }
    )

    let loaded = try await store.load()
    #expect(loaded.monthlyIncome == 0)
    #expect(loaded.monthlySavingsTarget == 0)
    #expect(loaded.emergencyFundMonthlyContribution == 0)
    #expect(loaded.fixedCosts.isEmpty)
}
