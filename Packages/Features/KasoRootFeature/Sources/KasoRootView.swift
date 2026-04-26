import SwiftUI
import ComposableArchitecture
import AppearanceDomain
import AppearanceFeature
import AuthDomain
import AuthFeature
import BudgetDomain
import OnboardingDomain
import OnboardingFeature
import TransactionDomain
import TransactionFeature

public struct KasoRootView: View {
    @Bindable private var store: StoreOf<KasoRootFeature>

    public init(
        appearanceSettingsRepository: AppearanceSettingsRepository = .empty,
        authRepository: AuthSessionRepository = .empty,
        budgetRepository: BudgetRepository = .empty,
        categoryRepository: TransactionCategoryRepository = .empty,
        onboardingProfileRepository: OnboardingProfileRepository = .empty,
        receiptImageRepository: ReceiptImageRepository = .empty,
        transactionRepository: TransactionRepository = .empty
    ) {
        store = Store(initialState: KasoRootFeature.State()) {
            KasoRootFeature()
        } withDependencies: {
            $0.appearanceSettingsRepository = appearanceSettingsRepository
            $0.authSessionRepository = authRepository
            $0.budgetRepository = budgetRepository
            $0.transactionCategoryRepository = categoryRepository
            $0.onboardingProfileRepository = onboardingProfileRepository
            $0.receiptImageRepository = receiptImageRepository
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
                    onAppearanceButtonTapped: {
                        store.send(.appearance(.settingsButtonTapped))
                    },
                    onSignOutButtonTapped: {
                        store.send(.auth(.signOutButtonTapped))
                    }
                )
            }
        }
        .tint(store.appearance.settings.accentColor.color)
        .preferredColorScheme(store.appearance.settings.mode.colorScheme)
        .sheet(isPresented: appearanceSettingsPresented) {
            AppearanceView(
                store: store.scope(
                    state: \.appearance,
                    action: \.appearance
                )
            )
        }
        .task {
            await store.send(.task).finish()
        }
    }

    private var appearanceSettingsPresented: Binding<Bool> {
        Binding(
            get: { store.appearance.isSettingsPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.appearance(.settingsDismissed))
                }
            }
        )
    }
}
