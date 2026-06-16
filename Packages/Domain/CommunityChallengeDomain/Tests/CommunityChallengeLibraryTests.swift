import Foundation
import Testing
@testable import CommunityChallengeDomain

struct CommunityChallengeLibraryTests {
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")

    // MARK: - Library contents

    @Test("library has exactly the seven bundled challenges")
    func libraryCount() {
        #expect(CommunityChallengeLibrary.challenges.count == 7)
    }

    @Test("library IDs are stable and unique")
    func libraryStableUniqueIDs() {
        let ids = CommunityChallengeLibrary.challenges.map(\.id)
        let expected = [
            "noSpend-week",
            "noSpend-month",
            "coffee-skip",
            "cook-at-home",
            "subscription-audit",
            "gratitude-log",
            "round-up-month",
        ]
        #expect(ids == expected)
        #expect(Set(ids).count == ids.count)
    }

    @Test("every bundled challenge has a positive duration")
    func libraryPositiveDurations() {
        for challenge in CommunityChallengeLibrary.challenges {
            #expect(challenge.durationDays > 0)
        }
    }

    @Test("every bundled challenge has non-empty localization keys")
    func libraryNonEmptyKeys() {
        for challenge in CommunityChallengeLibrary.challenges {
            #expect(!challenge.titleKey.isEmpty)
            #expect(!challenge.descriptionKey.isEmpty)
            #expect(!challenge.goalKey.isEmpty)
        }
    }

    @Test("library covers every difficulty level")
    func libraryCoversAllDifficulties() {
        let difficulties = Set(CommunityChallengeLibrary.challenges.map(\.difficulty))
        #expect(difficulties.contains(.easy))
        #expect(difficulties.contains(.medium))
        #expect(difficulties.contains(.hard))
    }

    @Test("library covers every category")
    func libraryCoversAllCategories() {
        let categories = Set(CommunityChallengeLibrary.challenges.map(\.category))
        for category in CommunityChallengeCategory.allCases {
            #expect(categories.contains(category))
        }
    }

    @Test("no-spend week challenge has the expected configuration")
    func noSpendWeekConfiguration() throws {
        let challenge = try #require(CommunityChallengeLibrary.challenge(id: "noSpend-week"))
        #expect(challenge.durationDays == 7)
        #expect(challenge.category == .noSpend)
        #expect(challenge.difficulty == .easy)
    }

    @Test("no-spend month challenge is the hardest 30-day no-spend variant")
    func noSpendMonthConfiguration() throws {
        let challenge = try #require(CommunityChallengeLibrary.challenge(id: "noSpend-month"))
        #expect(challenge.durationDays == 30)
        #expect(challenge.category == .noSpend)
        #expect(challenge.difficulty == .hard)
    }

    // MARK: - challenge(id:) lookup

    @Test("challenge(id:) returns the matching challenge")
    func lookupHit() throws {
        let challenge = try #require(CommunityChallengeLibrary.challenge(id: "gratitude-log"))
        #expect(challenge.id == "gratitude-log")
        #expect(challenge.category == .gratitude)
        #expect(challenge.durationDays == 21)
    }

    @Test("challenge(id:) returns nil for an unknown ID")
    func lookupMiss() {
        #expect(CommunityChallengeLibrary.challenge(id: "does-not-exist") == nil)
    }

    @Test("challenge(id:) returns nil for an empty ID")
    func lookupEmptyID() {
        #expect(CommunityChallengeLibrary.challenge(id: "") == nil)
    }

    @Test("challenge(id:) resolves every bundled ID")
    func lookupResolvesAll() {
        for challenge in CommunityChallengeLibrary.challenges {
            #expect(CommunityChallengeLibrary.challenge(id: challenge.id) == challenge)
        }
    }

    // MARK: - Repository.empty

    @Test("empty repository fetches no enrollments")
    func emptyRepositoryFetch() async throws {
        let repository = CommunityChallengeRepository.empty
        let enrollments = try await repository.fetchEnrollments()
        #expect(enrollments.isEmpty)
    }

    @Test("empty repository save and delete are no-ops that do not throw")
    func emptyRepositorySaveDelete() async throws {
        let repository = CommunityChallengeRepository.empty
        let id = try #require(fixedID)
        let enrollment = CommunityChallengeEnrollment(id: id, challengeID: "noSpend-week")
        try await repository.save(enrollment)
        try await repository.delete(id)
        // Still empty after a no-op save.
        let enrollments = try await repository.fetchEnrollments()
        #expect(enrollments.isEmpty)
    }

    // MARK: - Repository custom closures

    @Test("repository routes calls to its injected closures")
    func repositoryRoutesClosures() async throws {
        let id = try #require(fixedID)
        let stored = CommunityChallengeEnrollment(id: id, challengeID: "coffee-skip", checkedInDays: 4)
        let box = EnrollmentBox()
        let repository = CommunityChallengeRepository(
            fetchEnrollments: { await box.all() },
            save: { await box.add($0) },
            delete: { await box.remove($0) }
        )

        try await repository.save(stored)
        let afterSave = try await repository.fetchEnrollments()
        #expect(afterSave == [stored])

        try await repository.delete(id)
        let afterDelete = try await repository.fetchEnrollments()
        #expect(afterDelete.isEmpty)
    }
}

/// Minimal in-memory sink used to verify repository closure routing without a real backing store.
private actor EnrollmentBox {
    private var storage: [CommunityChallengeEnrollment] = []

    func all() -> [CommunityChallengeEnrollment] { storage }

    func add(_ enrollment: CommunityChallengeEnrollment) {
        storage.append(enrollment)
    }

    func remove(_ id: UUID) {
        storage.removeAll { $0.id == id }
    }
}
