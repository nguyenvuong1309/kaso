import CommunityChallengeDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct CommunityChallengeFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var enrollments: IdentifiedArrayOf<CommunityChallengeEnrollment>
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            enrollments: IdentifiedArrayOf<CommunityChallengeEnrollment> = [],
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.enrollments = enrollments
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }

        public var library: [CommunityChallenge] {
            CommunityChallengeLibrary.challenges
        }

        public func enrollment(for challengeID: String) -> CommunityChallengeEnrollment? {
            enrollments.first { $0.challengeID == challengeID }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case enrollmentsLoaded([CommunityChallengeEnrollment])
        case loadFailed(String)
        case joinButtonTapped(challengeID: String)
        case checkInButtonTapped(enrollmentID: UUID)
        case leaveButtonTapped(enrollmentID: UUID)
        case enrollmentSaved(CommunityChallengeEnrollment)
        case enrollmentRemoved(UUID)
        case saveFailed(String)
        case deleteFailed(String)
    }

    @Dependency(\.communityChallengeRepository) private var repository
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let items = try await repository.fetchEnrollments()
                        await send(.enrollmentsLoaded(items))
                    } catch {
                        await send(.loadFailed("communityChallenge.error.loadFailed"))
                    }
                }

            case let .enrollmentsLoaded(items):
                state.isLoading = false
                state.enrollments = IdentifiedArray(uniqueElements: items)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .joinButtonTapped(challengeID):
                guard state.enrollment(for: challengeID) == nil else { return .none }
                let enrollment = CommunityChallengeEnrollment(
                    id: uuid(),
                    challengeID: challengeID,
                    startedAt: date.now
                )
                return .run { send in
                    do {
                        try await repository.save(enrollment)
                        await send(.enrollmentSaved(enrollment))
                    } catch {
                        await send(.saveFailed("communityChallenge.error.saveFailed"))
                    }
                }

            case let .checkInButtonTapped(enrollmentID):
                guard var enrollment = state.enrollments[id: enrollmentID] else { return .none }
                guard
                    let challenge = CommunityChallengeLibrary.challenge(id: enrollment.challengeID)
                else { return .none }
                enrollment.checkedInDays = min(challenge.durationDays, enrollment.checkedInDays + 1)
                if enrollment.checkedInDays >= challenge.durationDays {
                    enrollment.isCompleted = true
                }
                let saved = enrollment
                return .run { send in
                    do {
                        try await repository.save(saved)
                        await send(.enrollmentSaved(saved))
                    } catch {
                        await send(.saveFailed("communityChallenge.error.saveFailed"))
                    }
                }

            case let .leaveButtonTapped(enrollmentID):
                return .run { send in
                    do {
                        try await repository.delete(enrollmentID)
                        await send(.enrollmentRemoved(enrollmentID))
                    } catch {
                        await send(.deleteFailed("communityChallenge.error.deleteFailed"))
                    }
                }

            case let .enrollmentSaved(enrollment):
                state.enrollments[id: enrollment.id] = enrollment
                return .none

            case let .enrollmentRemoved(id):
                state.enrollments.remove(id: id)
                return .none

            case let .saveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .deleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}
