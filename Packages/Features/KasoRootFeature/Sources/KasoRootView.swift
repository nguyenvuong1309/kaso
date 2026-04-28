import SwiftUI
import ComposableArchitecture
import AppearanceDomain
import AppearanceFeature
import AuthDomain
import AuthFeature
import BenchmarkFeature
import BudgetDomain
import DebtDomain
import DebtFeature
import FinancialAssistantFeature
import FreelancerDomain
import FreelancerFeature
import GamificationDomain
import GamificationFeature
import GoalDomain
import HoursOfLifeFeature
import InvestmentDomain
import InvestmentFeature
import KasoDesignSystem
import LegacyDomain
import LegacyFeature
import OnboardingDomain
import OnboardingFeature
import PhantomExpenseDomain
import PhantomExpenseFeature
import SleepCorrelationFeature
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
        benchmarkContextClient: BenchmarkContextClient = .empty,
        budgetRepository: BudgetRepository = .empty,
        categoryRepository: TransactionCategoryRepository = .empty,
        debtRepository: DebtRepository = .empty,
        debtLiabilitySyncClient: DebtLiabilitySyncClient = .empty,
        financialAssistantContextClient: FinancialAssistantContextClient = .empty,
        freelancerProfileRepository: FreelancerProfileRepository = .empty,
        gamificationProfileRepository: GamificationProfileRepository = .empty,
        gamificationContextClient: GamificationContextClient = .empty,
        holdingRepository: HoldingRepository = .empty,
        priceQuoteRepository: PriceQuoteRepository = .empty,
        targetAllocationRepository: TargetAllocationRepository = .empty,
        investmentAssetSyncClient: InvestmentAssetSyncClient = .empty,
        healthSleepClient: HealthSleepClient = .empty,
        sleepCorrelationDataClient: SleepCorrelationDataClient = .empty,
        legacyVaultRepository: LegacyVaultRepository = .empty,
        biometricAuthClient: BiometricAuthClient = .empty,
        legacyExportFileClient: LegacyExportFileClient = .empty,
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
            $0.benchmarkContextClient = benchmarkContextClient
            $0.budgetRepository = budgetRepository
            $0.transactionCategoryRepository = categoryRepository
            $0.debtRepository = debtRepository
            $0.debtLiabilitySyncClient = debtLiabilitySyncClient
            $0.financialAssistantContextClient = financialAssistantContextClient
            $0.freelancerProfileRepository = freelancerProfileRepository
            $0.gamificationProfileRepository = gamificationProfileRepository
            $0.gamificationContextClient = gamificationContextClient
            $0.holdingRepository = holdingRepository
            $0.priceQuoteRepository = priceQuoteRepository
            $0.targetAllocationRepository = targetAllocationRepository
            $0.investmentAssetSyncClient = investmentAssetSyncClient
            $0.healthSleepClient = healthSleepClient
            $0.sleepCorrelationDataClient = sleepCorrelationDataClient
            $0.legacyVaultRepository = legacyVaultRepository
            $0.biometricAuthClient = biometricAuthClient
            $0.legacyExportFileClient = legacyExportFileClient
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
                ZStack(alignment: .bottomTrailing) {
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

                    rootFloatingActions
                }
                .sheet(isPresented: benchmarkPresented) {
                    BenchmarkView(
                        store: store.scope(
                            state: \.benchmark,
                            action: \.benchmark
                        )
                    )
                }
                .sheet(isPresented: assistantPresented) {
                    FinancialAssistantView(
                        store: store.scope(
                            state: \.assistant,
                            action: \.assistant
                        )
                    )
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

    private var assistantPresented: Binding<Bool> {
        Binding(
            get: { store.assistant.isPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.assistant(.sheetDismissed))
                }
            }
        )
    }

    private var benchmarkPresented: Binding<Bool> {
        Binding(
            get: { store.benchmark.isPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.benchmark(.sheetDismissed))
                }
            }
        )
    }

    private var rootFloatingActions: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            Button {
                store.send(.benchmark(.floatingButtonTapped))
            } label: {
                Label {
                    Text("root.benchmark.open", bundle: .module)
                } icon: {
                    Image(systemName: "person.2.wave.2")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel(Text("root.benchmark.open", bundle: .module))

            assistantFloatingButton
        }
        .padding(Spacing.md)
    }

    private var assistantFloatingButton: some View {
        Button {
            store.send(.assistant(.floatingButtonTapped))
        } label: {
            Label {
                Text("root.assistant.open", bundle: .module)
            } icon: {
                Image(systemName: "sparkles")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel(Text("root.assistant.open", bundle: .module))
    }
}
