import SwiftUI
import ComposableArchitecture
import AppearanceDomain
import AppearanceFeature
import AuthDomain
import AuthFeature
import BudgetDomain
import DebtDomain
import DebtFeature
import GoalDomain
import HoursOfLifeFeature
import InvestmentDomain
import InvestmentFeature
import OnboardingDomain
import OnboardingFeature
import PhantomExpenseDomain
import PhantomExpenseFeature
import TransactionDomain
import TransactionFeature
import WealthDomain
import WealthFeature
import WellnessDomain
import WellnessFeature

public struct KasoRootView: View {
    @Bindable private var store: StoreOf<KasoRootFeature>

    public init(
        appearanceSettingsRepository: AppearanceSettingsRepository = .empty,
        authRepository: AuthSessionRepository = .empty,
        budgetRepository: BudgetRepository = .empty,
        categoryRepository: TransactionCategoryRepository = .empty,
        debtRepository: DebtRepository = .empty,
        debtLiabilitySyncClient: DebtLiabilitySyncClient = .empty,
        holdingRepository: HoldingRepository = .empty,
        priceQuoteRepository: PriceQuoteRepository = .empty,
        targetAllocationRepository: TargetAllocationRepository = .empty,
        investmentAssetSyncClient: InvestmentAssetSyncClient = .empty,
        phantomExpenseRepository: PhantomExpenseRepository = .empty,
        hoursOfLifeConfigurationRepository: HoursOfLifeConfigurationRepository = .empty,
        hoursOfLifeContextClient: HoursOfLifeContextClient = .empty,
        assetRepository: AssetRepository = .empty,
        liabilityRepository: LiabilityRepository = .empty,
        netWorthSnapshotRepository: NetWorthSnapshotRepository = .empty,
        onboardingProfileRepository: OnboardingProfileRepository = .empty,
        receiptImageRepository: ReceiptImageRepository = .empty,
        savingGoalRepository: SavingGoalRepository = .empty,
        transactionRepository: TransactionRepository = .empty
    ) {
        store = Store(initialState: KasoRootFeature.State()) {
            KasoRootFeature()
        } withDependencies: {
            $0.appearanceSettingsRepository = appearanceSettingsRepository
            $0.authSessionRepository = authRepository
            $0.budgetRepository = budgetRepository
            $0.transactionCategoryRepository = categoryRepository
            $0.debtRepository = debtRepository
            $0.debtLiabilitySyncClient = debtLiabilitySyncClient
            $0.holdingRepository = holdingRepository
            $0.priceQuoteRepository = priceQuoteRepository
            $0.targetAllocationRepository = targetAllocationRepository
            $0.investmentAssetSyncClient = investmentAssetSyncClient
            $0.phantomExpenseRepository = phantomExpenseRepository
            $0.hoursOfLifeConfigurationRepository = hoursOfLifeConfigurationRepository
            $0.hoursOfLifeContextClient = hoursOfLifeContextClient
            $0.assetRepository = assetRepository
            $0.liabilityRepository = liabilityRepository
            $0.netWorthSnapshotRepository = netWorthSnapshotRepository
            $0.onboardingProfileRepository = onboardingProfileRepository
            $0.receiptImageRepository = receiptImageRepository
            $0.savingGoalRepository = savingGoalRepository
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
                TabView {
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
                    .tabItem {
                        Label {
                            Text("root.tab.transactions", bundle: .module)
                        } icon: {
                            Image(systemName: "list.bullet.rectangle")
                        }
                    }

                    WealthView(
                        store: store.scope(
                            state: \.wealth,
                            action: \.wealth
                        )
                    )
                    .tabItem {
                        Label {
                            Text("root.tab.wealth", bundle: .module)
                        } icon: {
                            Image(systemName: "chart.pie")
                        }
                    }

                    InvestmentView(
                        store: store.scope(
                            state: \.investment,
                            action: \.investment
                        )
                    )
                    .tabItem {
                        Label {
                            Text("root.tab.investments", bundle: .module)
                        } icon: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                        }
                    }

                    WellnessView(
                        store: store.scope(
                            state: \.wellness,
                            action: \.wellness
                        )
                    )
                    .tabItem {
                        Label {
                            Text("root.tab.wellness", bundle: .module)
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                    }

                    DebtView(
                        store: store.scope(
                            state: \.debt,
                            action: \.debt
                        )
                    )
                    .tabItem {
                        Label {
                            Text("root.tab.debts", bundle: .module)
                        } icon: {
                            Image(systemName: "creditcard")
                        }
                    }
                }
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
