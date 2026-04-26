import Foundation
import GoalDomain
import PersistenceKit
import Testing

@Test("saves fetches and deletes saving goals encrypted")
func savesFetchesAndDeletesSavingGoalsEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("saving-goals.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let goal = SavingGoal(
        name: "Emergency fund",
        targetAmount: 30_000_000,
        currentAmount: 5_000_000,
        deadline: Date(timeIntervalSinceReferenceDate: 1_000),
        createdAt: Date(timeIntervalSinceReferenceDate: 100)
    )
    let store = EncryptedSavingGoalStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 17, count: 32) }
    )

    try await store.save(goal)

    let reloadedStore = EncryptedSavingGoalStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 17, count: 32) }
    )
    let loadedGoals = try await reloadedStore.fetchAll()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode([goal])

    #expect(loadedGoals == [goal])
    #expect(rawData != plainData)

    try await reloadedStore.delete(goal.id)

    let goalsAfterDelete = try await reloadedStore.fetchAll()
    #expect(goalsAfterDelete.isEmpty)
}
