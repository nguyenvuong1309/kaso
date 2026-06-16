import Foundation
import Testing
@testable import GoalDomain

@Test("empty repository fetches an empty list")
func repositoryEmptyFetchAll() async throws {
    let repository = SavingGoalRepository.empty
    let goals = try await repository.fetchAll()

    #expect(goals.isEmpty)
}

@Test("empty repository save and delete are no-ops")
func repositoryEmptySaveDelete() async throws {
    let repository = SavingGoalRepository.empty
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000DD"))
    let goal = SavingGoal(
        name: "Noop",
        targetAmount: 1_000_000,
        deadline: try repoDate(year: 2027, month: 1, day: 1)
    )

    // Should complete without throwing.
    try await repository.save(goal)
    try await repository.delete(id)
}

@Test("custom closures are invoked with their arguments")
func repositoryCustomClosures() async throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000EE"))
    let goal = SavingGoal(
        id: id,
        name: "Stored",
        targetAmount: 2_000_000,
        deadline: try repoDate(year: 2027, month: 1, day: 1)
    )
    let recorder = RepositoryRecorder()

    let repository = SavingGoalRepository(
        fetchAll: { [goal] },
        save: { await recorder.recordSaved($0) },
        delete: { await recorder.recordDeleted($0) }
    )

    let fetched = try await repository.fetchAll()
    try await repository.save(goal)
    try await repository.delete(id)

    #expect(fetched == [goal])
    #expect(await recorder.savedGoals == [goal])
    #expect(await recorder.deletedIDs == [id])
}

private actor RepositoryRecorder {
    private(set) var savedGoals: [SavingGoal] = []
    private(set) var deletedIDs: [UUID] = []

    func recordSaved(_ goal: SavingGoal) {
        savedGoals.append(goal)
    }

    func recordDeleted(_ id: UUID) {
        deletedIDs.append(id)
    }
}

private func repoFixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func repoDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: repoFixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
