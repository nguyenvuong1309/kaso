import Foundation
import Testing
@testable import RegretScoreDomain

@Test("empty repository fetchAll returns no ratings")
func emptyRepositoryFetchAll() async throws {
    let ratings = try await RegretRatingRepository.empty.fetchAll()
    #expect(ratings.isEmpty)
}

@Test("empty repository save and delete are no-ops that do not throw")
func emptyRepositorySaveDeleteNoOp() async throws {
    let rating = RegretRating(
        purchaseTitle: "Item",
        category: "food",
        amount: 100_000,
        score: .neutral,
        purchasedAt: Date(timeIntervalSince1970: 0)
    )
    try await RegretRatingRepository.empty.save(rating)
    try await RegretRatingRepository.empty.delete(rating.id)
}

@Test("repository routes calls to its injected closures")
func repositoryRoutesClosures() async throws {
    let recorder = RepositoryRecorder()
    let seeded = RegretRating(
        purchaseTitle: "Seed",
        category: "fashion",
        amount: 500_000,
        score: .regret,
        purchasedAt: Date(timeIntervalSince1970: 0)
    )

    let repository = RegretRatingRepository(
        fetchAll: { [seeded] },
        save: { rating in await recorder.recordSaved(rating) },
        delete: { id in await recorder.recordDeleted(id) }
    )

    let fetched = try await repository.fetchAll()
    #expect(fetched == [seeded])

    try await repository.save(seeded)
    #expect(await recorder.saved == [seeded])

    try await repository.delete(seeded.id)
    #expect(await recorder.deleted == [seeded.id])
}

@Test("repository propagates thrown errors from fetchAll")
func repositoryPropagatesErrors() async {
    let repository = RegretRatingRepository(
        fetchAll: { throw SampleError.boom },
        save: { _ in },
        delete: { _ in }
    )

    await #expect(throws: SampleError.boom) {
        _ = try await repository.fetchAll()
    }
}

@Test("empty reminder context client returns no candidates")
func emptyReminderContextClient() async throws {
    let candidates = try await RegretReminderContextClient.empty.fetchCandidates()
    #expect(candidates.isEmpty)
}

@Test("reminder context client routes to its injected closure")
func reminderContextClientRoutes() async throws {
    let expected = RegretReminderInput(
        transactionID: try #require(UUID(uuidString: "12121212-1212-1212-1212-121212121212")),
        title: "Item",
        category: "food",
        amount: 600_000,
        occurredAt: Date(timeIntervalSince1970: 0)
    )
    let client = RegretReminderContextClient(fetchCandidates: { [expected] })

    let candidates = try await client.fetchCandidates()

    #expect(candidates == [expected])
}

private enum SampleError: Error, Equatable {
    case boom
}

private actor RepositoryRecorder {
    private(set) var saved: [RegretRating] = []
    private(set) var deleted: [UUID] = []

    func recordSaved(_ rating: RegretRating) {
        saved.append(rating)
    }

    func recordDeleted(_ id: UUID) {
        deleted.append(id)
    }
}
