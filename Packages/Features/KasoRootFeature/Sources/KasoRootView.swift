import SwiftUI
import ComposableArchitecture
import AppearanceDomain
import AppearanceFeature
import AuthDomain
import AuthFeature
import BenchmarkFeature
import BNPLDomain
import BNPLFeature
import BudgetDomain
import CoolingOffDomain
import CoolingOffFeature
import DebtDomain
import DebtFeature
import FinancialAssistantFeature
import FreelancerDomain
import FreelancerFeature
import FutureSelfDomain
import FutureSelfFeature
import GamificationDomain
import GamificationFeature
import GiftTrackerDomain
import GiftTrackerFeature
import GoalDomain
import GuiltFreeBudgetDomain
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import HuiTrackerDomain
import HuiTrackerFeature
import InvestmentDomain
import InvestmentFeature
import KasoDesignSystem
import LegacyDomain
import LegacyFeature
import MoneyPersonalityDomain
import MoneyPersonalityFeature
import MoodJournalDomain
import MoodJournalFeature
import CloudSyncDomain
import CloudSyncFeature
import OnboardingDomain
import OnboardingFeature
import PaywallDomain
import PaywallFeature
import PhantomExpenseDomain
import PhantomExpenseFeature
import RegretScoreDomain
import RegretScoreFeature
import RoundUpDomain
import RoundUpFeature
import SeasonalPlannerDomain
import SeasonalPlannerFeature
import SleepCorrelationFeature
import SpendingCalendarDomain
import SpendingCalendarFeature
import SpendingDNADomain
import SpendingDNAFeature
import SpendingMapDomain
import SpendingMapFeature
import TransactionDomain
import TransactionFeature
import WealthDomain
import WealthFeature
import WellnessDomain
import WellnessFeature
import WhatIfDomain
import WhatIfFeature
import WrappedDomain
import WrappedFeature

public struct KasoRootView: View {
    @Bindable private var store: StoreOf<KasoRootFeature>

    public init(
        appearanceSettingsRepository: AppearanceSettingsRepository = .empty,
        authRepository: AuthSessionRepository = .empty,
        benchmarkContextClient: BenchmarkContextClient = .empty,
        bnplRepository: BNPLRepository = .empty,
        bnplContextClient: BNPLContextClient = .empty,
        budgetRepository: BudgetRepository = .empty,
        categoryRepository: TransactionCategoryRepository = .empty,
        coolingOffRepository: PurchasePlanRepository = .empty,
        debtRepository: DebtRepository = .empty,
        debtLiabilitySyncClient: DebtLiabilitySyncClient = .empty,
        financialAssistantContextClient: FinancialAssistantContextClient = .empty,
        freelancerProfileRepository: FreelancerProfileRepository = .empty,
        gamificationProfileRepository: GamificationProfileRepository = .empty,
        gamificationContextClient: GamificationContextClient = .empty,
        giftTrackerRepository: GiftTrackerRepository = .empty,
        huiTrackerRepository: HuiTrackerRepository = .empty,
        guiltFreeBudgetRepository: GuiltFreeBudgetRepository = .empty,
        holdingRepository: HoldingRepository = .empty,
        priceQuoteRepository: PriceQuoteRepository = .empty,
        targetAllocationRepository: TargetAllocationRepository = .empty,
        investmentAssetSyncClient: InvestmentAssetSyncClient = .empty,
        healthSleepClient: HealthSleepClient = .empty,
        sleepCorrelationDataClient: SleepCorrelationDataClient = .empty,
        legacyVaultRepository: LegacyVaultRepository = .empty,
        biometricAuthClient: BiometricAuthClient = .empty,
        legacyExportFileClient: LegacyExportFileClient = .empty,
        moneyPersonalityContextClient: MoneyPersonalityContextClient = .empty,
        moodJournalRepository: MoodJournalRepository = .empty,
        phantomExpenseRepository: PhantomExpenseRepository = .empty,
        hoursOfLifeConfigurationRepository: HoursOfLifeConfigurationRepository = .empty,
        hoursOfLifeContextClient: HoursOfLifeContextClient = .empty,
        assetRepository: AssetRepository = .empty,
        liabilityRepository: LiabilityRepository = .empty,
        netWorthSnapshotRepository: NetWorthSnapshotRepository = .empty,
        onboardingProfileRepository: OnboardingProfileRepository = .empty,
        paywallStoreClient: PaywallStoreClient = .empty,
        subscriptionEntitlementRepository: SubscriptionEntitlementRepository = .empty,
        cloudSyncClient: CloudSyncClient = .empty,
        cloudSyncPreferencesRepository: CloudSyncPreferencesRepository = .empty,
        receiptImageRepository: ReceiptImageRepository = .empty,
        regretRatingRepository: RegretRatingRepository = .empty,
        regretReminderContextClient: RegretReminderContextClient = .empty,
        roundUpRepository: RoundUpRepository = .empty,
        savingGoalRepository: SavingGoalRepository = .empty,
        seasonalContextClient: SeasonalContextClient = .empty,
        spendingCalendarContextClient: SpendingCalendarContextClient = .empty,
        spendingDNAContextClient: SpendingDNAContextClient = .empty,
        spendingMapRepository: SpendingMapRepository = .empty,
        futureSelfContextClient: FutureSelfContextClient = .empty,
        transactionRepository: TransactionRepository = .empty,
        transactionTemplateRepository: TransactionTemplateRepository = .empty,
        whatIfBaselineClient: WhatIfBaselineClient = .empty,
        wrappedContextClient: WrappedContextClient = .empty
    ) {
        store = Store(initialState: KasoRootFeature.State()) {
            KasoRootFeature()
        } withDependencies: {
            $0.appearanceSettingsRepository = appearanceSettingsRepository
            $0.authSessionRepository = authRepository
            $0.benchmarkContextClient = benchmarkContextClient
            $0.bnplRepository = bnplRepository
            $0.bnplContextClient = bnplContextClient
            $0.budgetRepository = budgetRepository
            $0.transactionCategoryRepository = categoryRepository
            $0.purchasePlanRepository = coolingOffRepository
            $0.debtRepository = debtRepository
            $0.debtLiabilitySyncClient = debtLiabilitySyncClient
            $0.financialAssistantContextClient = financialAssistantContextClient
            $0.freelancerProfileRepository = freelancerProfileRepository
            $0.gamificationProfileRepository = gamificationProfileRepository
            $0.gamificationContextClient = gamificationContextClient
            $0.giftTrackerRepository = giftTrackerRepository
            $0.huiTrackerRepository = huiTrackerRepository
            $0.guiltFreeBudgetRepository = guiltFreeBudgetRepository
            $0.holdingRepository = holdingRepository
            $0.priceQuoteRepository = priceQuoteRepository
            $0.targetAllocationRepository = targetAllocationRepository
            $0.investmentAssetSyncClient = investmentAssetSyncClient
            $0.healthSleepClient = healthSleepClient
            $0.sleepCorrelationDataClient = sleepCorrelationDataClient
            $0.legacyVaultRepository = legacyVaultRepository
            $0.biometricAuthClient = biometricAuthClient
            $0.legacyExportFileClient = legacyExportFileClient
            $0.moneyPersonalityContextClient = moneyPersonalityContextClient
            $0.moodJournalRepository = moodJournalRepository
            $0.phantomExpenseRepository = phantomExpenseRepository
            $0.hoursOfLifeConfigurationRepository = hoursOfLifeConfigurationRepository
            $0.hoursOfLifeContextClient = hoursOfLifeContextClient
            $0.assetRepository = assetRepository
            $0.liabilityRepository = liabilityRepository
            $0.netWorthSnapshotRepository = netWorthSnapshotRepository
            $0.onboardingProfileRepository = onboardingProfileRepository
            $0.paywallStoreClient = paywallStoreClient
            $0.subscriptionEntitlementRepository = subscriptionEntitlementRepository
            $0.cloudSyncClient = cloudSyncClient
            $0.cloudSyncPreferencesRepository = cloudSyncPreferencesRepository
            $0.receiptImageRepository = receiptImageRepository
            $0.regretRatingRepository = regretRatingRepository
            $0.regretReminderContextClient = regretReminderContextClient
            $0.roundUpRepository = roundUpRepository
            $0.savingGoalRepository = savingGoalRepository
            $0.seasonalContextClient = seasonalContextClient
            $0.spendingCalendarContextClient = spendingCalendarContextClient
            $0.spendingDNAContextClient = spendingDNAContextClient
            $0.spendingMapRepository = spendingMapRepository
            $0.futureSelfContextClient = futureSelfContextClient
            $0.transactionRepository = transactionRepository
            $0.transactionTemplateRepository = transactionTemplateRepository
            $0.whatIfBaselineClient = whatIfBaselineClient
            $0.wrappedContextClient = wrappedContextClient
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
                .sheet(isPresented: paywallPresented) {
                    PaywallView(
                        store: store.scope(
                            state: \.paywall,
                            action: \.paywall
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

    private var paywallPresented: Binding<Bool> {
        Binding(
            get: { store.isPaywallPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.paywallDismissed)
                }
            }
        )
    }

    private var rootFloatingActions: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            paywallFloatingButton
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

    private var paywallFloatingButton: some View {
        Button {
            store.send(.paywallButtonTapped)
        } label: {
            Label {
                Text("root.paywall.open", bundle: .module)
            } icon: {
                Image(systemName: "crown.fill")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityLabel(Text("root.paywall.open", bundle: .module))
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
