import Foundation
import Testing
import DebtDomain
import PersistenceKit

@Test("saves fetches and deletes debts encrypted")
func savesFetchesAndDeletesDebtsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("debts.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let debt = Debt(
        name: "Vay mua nhà",
        type: .mortgage,
        principal: 1_000_000_000,
        annualInterestRatePercent: 8,
        termMonths: 240,
        startDate: Date(timeIntervalSinceReferenceDate: 100),
        paymentDay: 5,
        createdAt: Date(timeIntervalSinceReferenceDate: 50)
    )
    let store = EncryptedDebtStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 43, count: 32) }
    )

    try await store.save(debt)

    let loadedDebts = try await store.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([debt])

    #expect(loadedDebts == [debt])
    #expect(rawData != plainData)

    try await store.delete(debt.id)
    #expect(try await store.fetchAll() == [])
}
