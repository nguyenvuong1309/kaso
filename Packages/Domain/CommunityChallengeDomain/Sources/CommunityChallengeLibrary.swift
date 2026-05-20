import Foundation

/// Bundled, evergreen challenges. Stable IDs let enrollments survive app updates.
public enum CommunityChallengeLibrary {
    public static let challenges: [CommunityChallenge] = [
        CommunityChallenge(
            id: "noSpend-week",
            titleKey: "communityChallenge.noSpendWeek.title",
            descriptionKey: "communityChallenge.noSpendWeek.description",
            goalKey: "communityChallenge.noSpendWeek.goal",
            durationDays: 7,
            category: .noSpend,
            difficulty: .easy
        ),
        CommunityChallenge(
            id: "noSpend-month",
            titleKey: "communityChallenge.noSpendMonth.title",
            descriptionKey: "communityChallenge.noSpendMonth.description",
            goalKey: "communityChallenge.noSpendMonth.goal",
            durationDays: 30,
            category: .noSpend,
            difficulty: .hard
        ),
        CommunityChallenge(
            id: "coffee-skip",
            titleKey: "communityChallenge.coffeeSkip.title",
            descriptionKey: "communityChallenge.coffeeSkip.description",
            goalKey: "communityChallenge.coffeeSkip.goal",
            durationDays: 14,
            category: .mindfulEating,
            difficulty: .medium
        ),
        CommunityChallenge(
            id: "cook-at-home",
            titleKey: "communityChallenge.cookAtHome.title",
            descriptionKey: "communityChallenge.cookAtHome.description",
            goalKey: "communityChallenge.cookAtHome.goal",
            durationDays: 14,
            category: .mindfulEating,
            difficulty: .medium
        ),
        CommunityChallenge(
            id: "subscription-audit",
            titleKey: "communityChallenge.subscriptionAudit.title",
            descriptionKey: "communityChallenge.subscriptionAudit.description",
            goalKey: "communityChallenge.subscriptionAudit.goal",
            durationDays: 7,
            category: .subscriptionCleanup,
            difficulty: .easy
        ),
        CommunityChallenge(
            id: "gratitude-log",
            titleKey: "communityChallenge.gratitudeLog.title",
            descriptionKey: "communityChallenge.gratitudeLog.description",
            goalKey: "communityChallenge.gratitudeLog.goal",
            durationDays: 21,
            category: .gratitude,
            difficulty: .easy
        ),
        CommunityChallenge(
            id: "round-up-month",
            titleKey: "communityChallenge.roundUpMonth.title",
            descriptionKey: "communityChallenge.roundUpMonth.description",
            goalKey: "communityChallenge.roundUpMonth.goal",
            durationDays: 30,
            category: .savingsBoost,
            difficulty: .medium
        ),
    ]

    public static func challenge(id: String) -> CommunityChallenge? {
        challenges.first { $0.id == id }
    }
}

public struct CommunityChallengeRepository: Sendable {
    public var fetchEnrollments: @Sendable () async throws -> [CommunityChallengeEnrollment]
    public var save: @Sendable (CommunityChallengeEnrollment) async throws -> Void
    public var delete: @Sendable (UUID) async throws -> Void

    public init(
        fetchEnrollments: @escaping @Sendable () async throws -> [CommunityChallengeEnrollment],
        save: @escaping @Sendable (CommunityChallengeEnrollment) async throws -> Void,
        delete: @escaping @Sendable (UUID) async throws -> Void
    ) {
        self.fetchEnrollments = fetchEnrollments
        self.save = save
        self.delete = delete
    }
}

public extension CommunityChallengeRepository {
    static let empty = CommunityChallengeRepository(
        fetchEnrollments: { [] },
        save: { _ in },
        delete: { _ in }
    )
}
