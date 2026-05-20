import CommunityChallengeDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct CommunityChallengeRootView: View {
    private let store: StoreOf<CommunityChallengeFeature>

    public init(repository: CommunityChallengeRepository = .empty) {
        store = Store(initialState: CommunityChallengeFeature.State()) {
            CommunityChallengeFeature()
        } withDependencies: {
            $0.communityChallengeRepository = repository
        }
    }

    public var body: some View {
        CommunityChallengeView(store: store)
    }
}

public struct CommunityChallengeView: View {
    private let store: StoreOf<CommunityChallengeFeature>

    public init(store: StoreOf<CommunityChallengeFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if store.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                KasoCard {
                    CommunityChallengeHeaderCard(activeCount: store.enrollments.count)
                }

                if store.enrollments.isEmpty == false {
                    KasoCard {
                        CommunityChallengeActiveCard(
                            enrollments: Array(store.enrollments),
                            onCheckIn: { store.send(.checkInButtonTapped(enrollmentID: $0.id)) },
                            onLeave: { store.send(.leaveButtonTapped(enrollmentID: $0.id)) }
                        )
                    }
                }

                ForEach(store.library) { challenge in
                    KasoCard {
                        CommunityChallengeBrowseCard(
                            challenge: challenge,
                            isEnrolled: store.enrollments.contains(where: { $0.challengeID == challenge.id }),
                            onJoin: {
                                store.send(.joinButtonTapped(challengeID: challenge.id))
                            }
                        )
                    }
                }

                if let messageKey = store.errorMessageKey {
                    CommunityChallengeErrorLabel(messageKey: messageKey)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
    }
}

private struct CommunityChallengeErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
