import SwiftUI
import DebtFeature
import HoursOfLifeFeature
import InvestmentFeature
import KasoRootFeature
import PersistenceKit

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let debtStore = EncryptedDebtStore()
    private let holdingStore = EncryptedHoldingStore()
    private let priceQuoteStore = EncryptedPriceQuoteStore()
    private let targetAllocationStore = EncryptedTargetAllocationStore()
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
                budgetRepository: budgetStore.repository(),
                categoryRepository: categoryStore.repository(),
                debtRepository: debtStore.repository(),
                debtLiabilitySyncClient: debtLiabilitySyncClient,
                holdingRepository: holdingStore.repository(),
                priceQuoteRepository: priceQuoteStore.repository(),
                targetAllocationRepository: targetAllocationStore.repository(),
                investmentAssetSyncClient: investmentAssetSyncClient,
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

    private var debtLiabilitySyncClient: DebtLiabilitySyncClient {
        let liabilityRepository = liabilityStore.repository()
        return DebtLiabilitySyncClient(
            replaceAutoTracked: { liabilities in
                try await liabilityRepository.replaceAutoTracked(liabilities)
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
