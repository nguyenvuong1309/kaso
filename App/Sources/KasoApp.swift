import SwiftUI
import BenchmarkFeature
import DebtFeature
import FinancialAssistantFeature
import FreelancerFeature
import GamificationFeature
import HoursOfLifeFeature
import InvestmentFeature
import KasoRootFeature
import LegacyFeature
import PersistenceKit
import SleepCorrelationDomain
import SleepCorrelationFeature

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let debtStore = EncryptedDebtStore()
    private let freelancerProfileStore = EncryptedFreelancerProfileStore()
    private let gamificationProfileStore = EncryptedGamificationProfileStore()
    private let holdingStore = EncryptedHoldingStore()
    private let priceQuoteStore = EncryptedPriceQuoteStore()
    private let targetAllocationStore = EncryptedTargetAllocationStore()
    private let legacyVaultStore = EncryptedLegacyVaultStore()
    private let phantomExpenseStore = EncryptedPhantomExpenseStore()
    private let hoursOfLifeConfigurationStore = EncryptedHoursOfLifeConfigurationStore()
    private let assetStore = EncryptedAssetStore()
    private let liabilityStore = EncryptedLiabilityStore()
    private let netWorthSnapshotStore = EncryptedNetWorthSnapshotStore()
    private let onboardingStore = KeychainOnboardingProfileStore()
    private let receiptImageStore = EncryptedReceiptImageStore()
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
                debtRepository: debtStore.repository(),
                debtLiabilitySyncClient: debtLiabilitySyncClient,
                financialAssistantContextClient: financialAssistantContextClient,
                freelancerProfileRepository: freelancerProfileStore.repository(),
                gamificationProfileRepository: gamificationProfileStore.repository(),
                gamificationContextClient: gamificationContextClient,
                holdingRepository: holdingStore.repository(),
                priceQuoteRepository: priceQuoteStore.repository(),
                targetAllocationRepository: targetAllocationStore.repository(),
                investmentAssetSyncClient: investmentAssetSyncClient,
                healthSleepClient: healthSleepClient,
                sleepCorrelationDataClient: sleepCorrelationDataClient,
                legacyVaultRepository: legacyVaultStore.repository(),
                biometricAuthClient: .live,
                legacyExportFileClient: .live,
                phantomExpenseRepository: phantomExpenseStore.repository(),
                hoursOfLifeConfigurationRepository: hoursOfLifeConfigurationStore.repository(),
                hoursOfLifeContextClient: hoursOfLifeContextClient,
                assetRepository: assetStore.repository(),
                liabilityRepository: liabilityStore.repository(),
                netWorthSnapshotRepository: netWorthSnapshotStore.repository(),
                onboardingProfileRepository: onboardingStore.repository(),
                receiptImageRepository: receiptImageStore.repository(),
                savingGoalRepository: savingGoalStore.repository(),
                transactionRepository: transactionStore.repository()
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
}
