import SwiftUI
import BenchmarkFeature
import CoolingOffFeature
import DebtFeature
import FinancialAssistantFeature
import FreelancerFeature
import GamificationFeature
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import InvestmentFeature
import KasoRootFeature
import LegacyFeature
import MoodJournalFeature
import PersistenceKit
import RegretScoreDomain
import RegretScoreFeature
import RoundUpFeature
import SleepCorrelationDomain
import SleepCorrelationFeature
import SpendingCalendarDomain
import SpendingCalendarFeature
import SubscriptionDomain
import TransactionDomain
import WhatIfDomain
import WhatIfFeature

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let coolingOffStore = EncryptedPurchasePlanStore()
    private let debtStore = EncryptedDebtStore()
    private let freelancerProfileStore = EncryptedFreelancerProfileStore()
    private let gamificationProfileStore = EncryptedGamificationProfileStore()
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
    private let transactionStore = EncryptedTransactionStore()

    var body: some Scene {
        WindowGroup {
            KasoRootView(
                appearanceSettingsRepository: appearanceStore.repository(),
                authRepository: authStore.repository(),
                benchmarkContextClient: benchmarkContextClient,
                budgetRepository: budgetStore.repository(),
                categoryRepository: categoryStore.repository(),
                coolingOffRepository: coolingOffStore.repository(),
                debtRepository: debtStore.repository(),
                debtLiabilitySyncClient: debtLiabilitySyncClient,
                financialAssistantContextClient: financialAssistantContextClient,
                freelancerProfileRepository: freelancerProfileStore.repository(),
                gamificationProfileRepository: gamificationProfileStore.repository(),
                gamificationContextClient: gamificationContextClient,
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
                spendingCalendarContextClient: spendingCalendarContextClient,
                transactionRepository: transactionStore.repository(),
                whatIfBaselineClient: whatIfBaselineClient
            )
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
                let detection = SubscriptionDetector().detect(transactions: transactions)
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
                let monthlyIncome: Decimal = {
                    if incomeTotal > 0 {
                        return incomeTotal / monthsCovered
                    }
                    let onboardingIncome = try? await onboardingRepository.load()?.monthlyIncome
                    return onboardingIncome ?? 0
                }()
                let monthlyExpenses = expenseTotal / monthsCovered
                return WhatIfBaseline(
                    monthlyIncome: monthlyIncome,
                    monthlyExpenses: monthlyExpenses
                )
            }
        )
    }
}
