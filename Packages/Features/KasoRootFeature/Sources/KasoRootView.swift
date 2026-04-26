import AuthDomain
import AuthFeature
import ComposableArchitecture
import OnboardingDomain
import OnboardingFeature
import SwiftUI
import TransactionDomain
import TransactionFeature

public struct KasoRootView: View {
    @Bindable private var store: StoreOf<KasoRootFeature>

    public init(
        authRepository: AuthSessionRepository = .empty,
        onboardingProfileRepository: OnboardingProfileRepository = .empty,
        transactionRepository: TransactionRepository = .empty
    ) {
        store = Store(initialState: KasoRootFeature.State()) {
            KasoRootFeature()
        } withDependencies: {
            $0.authSessionRepository = authRepository
            $0.onboardingProfileRepository = onboardingProfileRepository
            $0.transactionRepository = transactionRepository
        }
    }

    public var body: some View {
        Group {
            if store.auth.session == nil {
                AuthView(
                    store: store.scope(state: \.auth, action: \.auth)
                )
            } else if store.onboarding.profile == nil {
                OnboardingView(
                    store: store.scope(
                        state: \.onboarding,
                        action: \.onboarding
                    )
                )
            } else {
                TransactionView(
                    store: store.scope(
                        state: \.transaction,
                        action: \.transaction
                    ),
                    onSignOutButtonTapped: {
                        store.send(.auth(.signOutButtonTapped))
                    }
                )
            }
        }
    }
}
