import SwiftUI
import DebtFeature
import KasoRootFeature
import PersistenceKit

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let debtStore = EncryptedDebtStore()
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

    private var debtLiabilitySyncClient: DebtLiabilitySyncClient {
        let liabilityRepository = liabilityStore.repository()
        return DebtLiabilitySyncClient(
            replaceAutoTracked: { liabilities in
                try await liabilityRepository.replaceAutoTracked(liabilities)
            }
        )
    }
}
