import SwiftUI
import BenchmarkFeature
import BNPLDomain
import BudgetDomain
import CloudSyncDomain
import KasoWidgetShared
import PaywallDomain
import CoolingOffFeature
import DebtFeature
import MoneyPersonalityDomain
import FinancialAssistantFeature
import FreelancerFeature
import FutureSelfDomain
import GamificationFeature
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import InvestmentFeature
import KasoDesignSystem
import KasoFoundation
import KasoRootFeature
import LegacyFeature
import MoodJournalFeature
import PersistenceKit
import RegretScoreDomain
import RegretScoreFeature
import RoundUpFeature
import SeasonalPlannerDomain
import SleepCorrelationDomain
import SleepCorrelationFeature
import SpendingCalendarDomain
import SpendingCalendarFeature
import SpendingDNADomain
import SpendingMapDomain
import SubscriptionDomain
import TransactionDomain
import WhatIfDomain
import WhatIfFeature
import WrappedDomain

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let bnplStore = EncryptedBNPLStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let coolingOffStore = EncryptedPurchasePlanStore()
    private let debtStore = EncryptedDebtStore()
    private let freelancerProfileStore = EncryptedFreelancerProfileStore()
    private let gamificationProfileStore = EncryptedGamificationProfileStore()
    private let giftTrackerStore = EncryptedGiftTrackerStore()
    private let huiTrackerStore = EncryptedHuiTrackerStore()
    private let guiltFreeBudgetStore = EncryptedGuiltFreeBudgetConfigurationStore()
    private let holdingStore = EncryptedHoldingStore()
    private let priceQuoteStore = EncryptedPriceQuoteStore()
    private let targetAllocationStore = EncryptedTargetAllocationStore()
    private let legacyVaultStore = EncryptedLegacyVaultStore()
    private let moodJournalStore = EncryptedMoodJournalStore()
    private let phantomExpenseStore = EncryptedPhantomExpenseStore()
    private let hoursOfLifeConfigurationStore = EncryptedHoursOfLifeConfigurationStore()
    private let assetStore = EncryptedAssetStore()
    private let liabilityStore = EncryptedLiabilityStore()
    private let netWorthSnapshotStore = EncryptedNetWorthSnapshotStore()
    private let onboardingStore = KeychainOnboardingProfileStore()
    private let receiptImageStore = EncryptedReceiptImageStore()
    private let regretRatingStore = EncryptedRegretRatingStore()
    private let roundUpStore = EncryptedRoundUpStore()
    private let savingGoalStore = EncryptedSavingGoalStore()
    private let spendingMapStore = EncryptedSpendingMapStore()
    private let subscriptionEntitlementStore = EncryptedSubscriptionEntitlementStore()
    private let paywallPromptScheduleStore = EncryptedPaywallPromptScheduleStore()
    private let cloudSyncPreferencesStore = EncryptedCloudSyncPreferencesStore()
    private let transactionStore = EncryptedTransactionStore()
    private let transactionTemplateStore = EncryptedTransactionTemplateStore()

    private let widgetSnapshotPublisher = WidgetSnapshotPublisher()

    var body: some Scene {
        WindowGroup {
            KasoRootView(
                appearanceSettingsRepository: appearanceStore.repository(),
                authRepository: authStore.repository(),
                benchmarkContextClient: benchmarkContextClient,
                bnplRepository: bnplStore.repository(),
                bnplContextClient: bnplContextClient,
                budgetRepository: budgetStore.repository(),
                categoryRepository: categoryStore.repository(),
                coolingOffRepository: coolingOffStore.repository(),
                debtRepository: debtStore.repository(),
                debtLiabilitySyncClient: debtLiabilitySyncClient,
                financialAssistantContextClient: financialAssistantContextClient,
                freelancerProfileRepository: freelancerProfileStore.repository(),
                gamificationProfileRepository: gamificationProfileStore.repository(),
                gamificationContextClient: gamificationContextClient,
                giftTrackerRepository: giftTrackerStore.repository(),
                huiTrackerRepository: huiTrackerStore.repository(),
                guiltFreeBudgetRepository: guiltFreeBudgetStore.repository(),
                holdingRepository: holdingStore.repository(),
                priceQuoteRepository: priceQuoteStore.repository(),
                targetAllocationRepository: targetAllocationStore.repository(),
                investmentAssetSyncClient: investmentAssetSyncClient,
                healthSleepClient: healthSleepClient,
                sleepCorrelationDataClient: sleepCorrelationDataClient,
                legacyVaultRepository: legacyVaultStore.repository(),
                biometricAuthClient: .live,
                legacyExportFileClient: .live,
                moneyPersonalityContextClient: moneyPersonalityContextClient,
                moodJournalRepository: moodJournalStore.repository(),
                phantomExpenseRepository: phantomExpenseStore.repository(),
                hoursOfLifeConfigurationRepository: hoursOfLifeConfigurationStore.repository(),
                hoursOfLifeContextClient: hoursOfLifeContextClient,
                assetRepository: assetStore.repository(),
                liabilityRepository: liabilityStore.repository(),
                netWorthSnapshotRepository: netWorthSnapshotStore.repository(),
                onboardingProfileRepository: onboardingStore.repository(),
                receiptImageRepository: receiptImageStore.repository(),
                regretRatingRepository: regretRatingStore.repository(),
                regretReminderContextClient: regretReminderContextClient,
                roundUpRepository: roundUpStore.repository(),
                savingGoalRepository: savingGoalStore.repository(),
                seasonalContextClient: seasonalContextClient,
                spendingCalendarContextClient: spendingCalendarContextClient,
                spendingDNAContextClient: spendingDNAContextClient,
                spendingMapRepository: spendingMapStore.repository(),
                paywallStoreClient: LivePaywallStoreClient.make(),
                subscriptionEntitlementRepository: subscriptionEntitlementStore.repository(),
                paywallPromptScheduleRepository: paywallPromptScheduleStore.repository(),
                cloudSyncClient: LiveCloudSyncClient.make(),
                cloudSyncPreferencesRepository: cloudSyncPreferencesStore.repository(),
                futureSelfContextClient: futureSelfContextClient,
                transactionRepository: makeTransactionRepository(),
                transactionTemplateRepository: transactionTemplateStore.repository(),
                whatIfBaselineClient: whatIfBaselineClient,
                wrappedContextClient: wrappedContextClient
            )
            .task {
                await refreshWidgetSnapshot()
            }
            .environmentBadge(
                AppConfiguration.current.environment == .dev ? "DEV" : nil
            )
        }
    }

    /// Wraps the encrypted transaction repository so every persisted save also
    /// kicks the widget/Live Activity snapshot refresh. Keeps `TransactionFeature`
    /// free of any widget-layer dependency.
    private func makeTransactionRepository() -> TransactionRepository {
        let base = transactionStore.repository()
        return TransactionRepository(
            fetchAll: base.fetchAll,
            save: { [self] transaction in
                try await base.save(transaction)
                await refreshWidgetSnapshot()
            }
        )
    }

    private func refreshWidgetSnapshot() async {
        let transactionRepository = transactionStore.repository()
        let budgetRepository = budgetStore.repository()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? startOfDay
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now

        let transactions = (try? await transactionRepository.fetchAll()) ?? []
        let budgets: [Budget] = (try? await budgetRepository.fetchAll()) ?? []

        let todayExpenses = transactions.filter {
            $0.kind == .expense && $0.occurredAt >= startOfDay && $0.occurredAt < calendar.date(
                byAdding: .day, value: 1, to: startOfDay
            ) ?? now
        }
        let monthExpenses = transactions.filter {
            $0.kind == .expense && $0.occurredAt >= startOfMonth && $0.occurredAt < monthEnd
        }

        let totalToday = todayExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let monthlyLimit = budgets.reduce(Decimal(0)) { $0 + $1.monthlyLimit }
        let monthlySpent = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }

        let snapshot = WidgetSnapshot(
            totalSpentToday: totalToday,
            monthlyBudgetLimit: monthlyLimit,
            monthlyBudgetSpent: monthlySpent,
            transactionCountToday: todayExpenses.count,
            currencyCode: "VND",
            updatedAt: now
        )
        await widgetSnapshotPublisher.publish(snapshot)
        if #available(iOS 16.2, *) {
            let label = String(localized: "live.activity.sessionLabel")
            await KasoLiveActivityClient.shared.apply(snapshot: snapshot, sessionLabel: label)
        }
    }

    private var gamificationContextClient: GamificationContextClient {
        let transactionRepository = transactionStore.repository()
        let budgetRepository = budgetStore.repository()
        return GamificationContextClient(
            loadTransactions: {
                try await transactionRepository.fetchAll()
            },
            loadBudgets: {
                try await budgetRepository.fetchAll()
            }
        )
    }

    private var hoursOfLifeContextClient: HoursOfLifeContextClient {
        let transactionRepository = transactionStore.repository()
        let onboardingRepository = onboardingStore.repository()
        return HoursOfLifeContextClient(
            recentTransactions: {
                try await transactionRepository.fetchAll()
            },
            defaultMonthlyIncome: {
                try await onboardingRepository.load()?.monthlyIncome
            }
        )
    }

    private var financialAssistantContextClient: FinancialAssistantContextClient {
        let transactionRepository = transactionStore.repository()
        return FinancialAssistantContextClient(
            loadTransactions: {
                try await transactionRepository.fetchAll()
            }
        )
    }

    private var benchmarkContextClient: BenchmarkContextClient {
        let transactionRepository = transactionStore.repository()
        let onboardingRepository = onboardingStore.repository()
        return BenchmarkContextClient(
            loadTransactions: {
                try await transactionRepository.fetchAll()
            },
            defaultMonthlyIncome: {
                try await onboardingRepository.load()?.monthlyIncome
            }
        )
    }

    private var moneyPersonalityContextClient: MoneyPersonalityContextClient {
        let transactionRepository = transactionStore.repository()
        let budgetRepository = budgetStore.repository()
        let savingGoalRepository = savingGoalStore.repository()
        return MoneyPersonalityContextClient(
            load: {
                let transactions = try await transactionRepository.fetchAll()
                let budgets = (try? await budgetRepository.fetchAll()) ?? []
                let goals = (try? await savingGoalRepository.fetchAll()) ?? []

                let calendar = Calendar.current
                let now = Date()
                let cutoff = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                let recent = transactions.filter { $0.occurredAt >= cutoff }

                let inputs = recent.map { transaction in
                    PersonalityTransactionInput(
                        amount: transaction.amount,
                        categoryID: transaction.category.id,
                        isExpense: transaction.kind == .expense,
                        occurredAt: transaction.occurredAt,
                        calendar: calendar
                    )
                }

                let totalBudgetLimit = budgets.reduce(Decimal(0)) { $0 + $1.monthlyLimit }
                let totalBudgetSpent = budgets.reduce(Decimal(0)) { $0 + $1.spent }
                let budgetUtilizationRatio: Double = {
                    guard totalBudgetLimit > 0 else { return 0.5 }
                    return NSDecimalNumber(decimal: totalBudgetSpent / totalBudgetLimit).doubleValue
                }()

                let totalIncome = recent
                    .filter { $0.kind == .income }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                let totalSavings = goals.reduce(Decimal(0)) { $0 + $1.currentAmount }
                let savingsRate: Double = {
                    guard totalIncome > 0 else { return 0 }
                    return NSDecimalNumber(decimal: totalSavings / totalIncome).doubleValue
                }()

                return MoneyPersonalityContext(
                    transactions: inputs,
                    budgetUtilizationRatio: budgetUtilizationRatio,
                    savingsRate: savingsRate
                )
            }
        )
    }

    private var bnplContextClient: BNPLContextClient {
        let onboardingRepository = onboardingStore.repository()
        let transactionRepository = transactionStore.repository()
        return BNPLContextClient(
            monthlyIncome: {
                if let onboardingIncome = try? await onboardingRepository.load()?.monthlyIncome {
                    return onboardingIncome
                }
                let transactions = try await transactionRepository.fetchAll()
                let calendar = Calendar.current
                let now = Date()
                let cutoff = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                let income = transactions
                    .filter { $0.kind == .income && $0.occurredAt >= cutoff }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                return income > 0 ? income / 3 : 0
            }
        )
    }

    private var debtLiabilitySyncClient: DebtLiabilitySyncClient {
        let liabilityRepository = liabilityStore.repository()
        return DebtLiabilitySyncClient(
            replaceAutoTracked: { liabilities in
                try await liabilityRepository.replaceAutoTracked(liabilities)
            }
        )
    }

    private var healthSleepClient: HealthSleepClient {
        .live
    }

    private var sleepCorrelationDataClient: SleepCorrelationDataClient {
        let transactionRepository = transactionStore.repository()
        let sleepClient = HealthSleepClient.live
        return SleepCorrelationDataClient(
            loadDataPoints: {
                let sleepSamples = try await sleepClient.sleepSamples()
                let transactions = try await transactionRepository.fetchAll()
                return SleepSpendingDataBuilder.makeDataPoints(
                    sleepSamples: sleepSamples,
                    transactions: transactions
                )
            }
        )
    }

    private var investmentAssetSyncClient: InvestmentAssetSyncClient {
        let assetRepository = assetStore.repository()
        return InvestmentAssetSyncClient(
            replaceAutoTracked: { assets in
                try await assetRepository.replaceAutoTracked(assets)
            }
        )
    }

    private var regretReminderContextClient: RegretReminderContextClient {
        let transactionRepository = transactionStore.repository()
        return RegretReminderContextClient(
            fetchCandidates: {
                let transactions = try await transactionRepository.fetchAll()
                return transactions
                    .filter { $0.kind == .expense }
                    .map { transaction in
                        RegretReminderInput(
                            transactionID: transaction.id,
                            title: transaction.note ?? transaction.category.id,
                            category: transaction.category.id,
                            amount: transaction.amount,
                            occurredAt: transaction.occurredAt
                        )
                    }
            }
        )
    }

    private var seasonalContextClient: SeasonalContextClient {
        let transactionRepository = transactionStore.repository()
        return SeasonalContextClient(
            loadTransactions: {
                let transactions = try await transactionRepository.fetchAll()
                return transactions.map { transaction in
                    SeasonalTransactionInput(
                        amount: transaction.amount,
                        isExpense: transaction.kind == .expense,
                        occurredAt: transaction.occurredAt
                    )
                }
            }
        )
    }

    private var spendingCalendarContextClient: SpendingCalendarContextClient {
        let transactionRepository = transactionStore.repository()
        return SpendingCalendarContextClient(
            fetchTransactions: {
                let transactions = try await transactionRepository.fetchAll()
                return transactions
                    .filter { $0.kind == .expense }
                    .map { transaction in
                        SpendingCalendarTransaction(
                            amount: transaction.amount,
                            occurredAt: transaction.occurredAt,
                            label: transaction.note ?? transaction.category.id,
                            category: transaction.category.id
                        )
                    }
            },
            fetchRecurringEvents: {
                let transactions = try await transactionRepository.fetchAll()
                let detection = SubscriptionDetector().detect(from: transactions)
                return detection.subscriptions.map { sub in
                    SpendingCalendarRecurringEvent(
                        label: sub.name,
                        amount: sub.averageAmount,
                        firstOccurrence: sub.nextBillingDate,
                        intervalDays: sub.interval.approximateDays,
                        category: sub.category.id
                    )
                }
            }
        )
    }

    private var spendingDNAContextClient: SpendingDNAContextClient {
        let transactionRepository = transactionStore.repository()
        return SpendingDNAContextClient(
            loadTransactions: {
                let transactions = try await transactionRepository.fetchAll()
                return transactions.map { transaction in
                    SpendingDNATransactionInput(
                        amount: transaction.amount,
                        categoryID: transaction.category.id,
                        isExpense: transaction.kind == .expense,
                        occurredAt: transaction.occurredAt
                    )
                }
            }
        )
    }

    private var futureSelfContextClient: FutureSelfContextClient {
        let transactionRepository = transactionStore.repository()
        return FutureSelfContextClient(
            loadContext: {
                let transactions = try await transactionRepository.fetchAll()
                let inputs = transactions.map { transaction in
                    FutureSelfTransactionInput(
                        amount: transaction.amount,
                        isExpense: transaction.kind == .expense,
                        occurredAt: transaction.occurredAt
                    )
                }
                return FutureSelfContext(transactions: inputs, currentAge: nil)
            }
        )
    }

    private var wrappedContextClient: WrappedContextClient {
        let transactionRepository = transactionStore.repository()
        return WrappedContextClient(
            loadTransactions: {
                let transactions = try await transactionRepository.fetchAll()
                return transactions.map { transaction in
                    WrappedTransactionInput(
                        amount: transaction.amount,
                        categoryID: transaction.category.id,
                        isExpense: transaction.kind == .expense,
                        occurredAt: transaction.occurredAt
                    )
                }
            }
        )
    }

    private var whatIfBaselineClient: WhatIfBaselineClient {
        let transactionRepository = transactionStore.repository()
        let onboardingRepository = onboardingStore.repository()
        return WhatIfBaselineClient(
            load: {
                let transactions = try await transactionRepository.fetchAll()
                let calendar = Calendar.current
                let now = Date()
                let cutoff = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                let recent = transactions.filter { $0.occurredAt >= cutoff }
                let expenseTotal = recent
                    .filter { $0.kind == .expense }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                let incomeTotal = recent
                    .filter { $0.kind == .income }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                let monthsCovered: Decimal = recent.isEmpty ? 1 : 3
                let monthlyIncome: Decimal
                if incomeTotal > 0 {
                    monthlyIncome = incomeTotal / monthsCovered
                } else {
                    let onboardingIncome = try? await onboardingRepository.load()?.monthlyIncome
                    monthlyIncome = onboardingIncome ?? 0
                }
                let monthlyExpenses = expenseTotal / monthsCovered
                return WhatIfBaseline(
                    monthlyIncome: monthlyIncome,
                    monthlyExpenses: monthlyExpenses
                )
            }
        )
    }
}
