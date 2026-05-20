import CommunityChallengeDomain
import ComposableArchitecture
import Foundation

private enum CommunityChallengeRepositoryKey: DependencyKey {
    static let liveValue = CommunityChallengeRepository.empty
    static let previewValue = CommunityChallengeRepository.preview
    static let testValue = CommunityChallengeRepository.empty
}

public extension CommunityChallengeRepository {
    static let preview = CommunityChallengeRepository(
        fetchEnrollments: {
            [
                CommunityChallengeEnrollment(
                    challengeID: "noSpend-week",
                    startedAt: Date().addingTimeInterval(-86_400 * 2),
                    checkedInDays: 2
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var communityChallengeRepository: CommunityChallengeRepository {
        get { self[CommunityChallengeRepositoryKey.self] }
        set { self[CommunityChallengeRepositoryKey.self] = newValue }
    }
}
