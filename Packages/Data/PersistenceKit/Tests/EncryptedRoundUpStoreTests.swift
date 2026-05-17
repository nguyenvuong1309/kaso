import Foundation
import PersistenceKit
import RoundUpDomain
import Testing

@Test("round-up store persists rule and entries encrypted")
func roundUpStorePersistsRuleAndEntries() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("round-up.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let store = EncryptedRoundUpStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 41, count: 32) }
    )

    let rule = RoundUpRule(isEnabled: true, step: .tenThousand)
    try await store.saveRule(rule)

    let entry = RoundUpEntry(
        originalAmount: 85_000,
        roundedAmount: 90_000,
        contribution: 5_000,
        step: .tenThousand,
        createdAt: Date(timeIntervalSinceReferenceDate: 0)
    )
    try await store.saveEntry(entry)

    let loadedRule = try await store.loadRule()
    let loadedEntries = try await store.fetchEntries()
    let rawData = try Data(contentsOf: fileURL)

    #expect(loadedRule == rule)
    #expect(loadedEntries == [entry])
    #expect(rawData.isEmpty == false)

    try await store.deleteEntry(entry.id)
    #expect(try await store.fetchEntries() == [])

    try await store.clearAll()
    #expect(try await store.fetchEntries() == [])
}
