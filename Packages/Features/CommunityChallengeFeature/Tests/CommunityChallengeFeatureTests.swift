import CommunityChallengeDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import CommunityChallengeFeature

@MainActor
struct CommunityChallengeFeatureTests {
    @Test("join button creates enrollment")
    func joinCreatesEnrollment() async {
        let fixedID = UUID(uuidString: "00000000-0000-0000-0000-00000000A101")!
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let saved = LockIsolated<[CommunityChallengeEnrollment]>([])

        let store = TestStore(initialState: CommunityChallengeFeature.State()) {
            CommunityChallengeFeature()
        } withDependencies: {
            $0.communityChallengeRepository = CommunityChallengeRepository(
                fetchEnrollments: { saved.value },
                save: { enrollment in saved.withValue { $0.append(enrollment) } },
                delete: { _ in }
            )
            $0.date = .constant(fixedDate)
            $0.uuid = .constant(fixedID)
        }

        await store.send(.joinButtonTapped(challengeID: "noSpend-week"))

        let expected = CommunityChallengeEnrollment(
            id: fixedID,
            challengeID: "noSpend-week",
            startedAt: fixedDate
        )
        await store.receive(\.enrollmentSaved) {
            $0.enrollments = [expected]
        }
        #expect(saved.value == [expected])
    }

    @Test("check-in increments count and completes at duration")
    func checkInIncrements() async {
        let enrollment = CommunityChallengeEnrollment(
            challengeID: "noSpend-week",
            checkedInDays: 6
        )
        let store = TestStore(
            initialState: CommunityChallengeFeature.State(enrollments: [enrollment])
        ) {
            CommunityChallengeFeature()
        } withDependencies: {
            $0.communityChallengeRepository = CommunityChallengeRepository(
                fetchEnrollments: { [enrollment] },
                save: { _ in },
                delete: { _ in }
            )
        }

        await store.send(.checkInButtonTapped(enrollmentID: enrollment.id))

        var expected = enrollment
        expected.checkedInDays = 7
        expected.isCompleted = true
        await store.receive(\.enrollmentSaved) {
            $0.enrollments[id: enrollment.id] = expected
        }
    }
}
