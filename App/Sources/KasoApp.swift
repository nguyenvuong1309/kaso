import SwiftUI
import KasoRootFeature
import PersistenceKit

@main
struct KasoApp: App {
    private let appearanceStore = UserDefaultsAppearanceSettingsStore()
    private let authStore = KeychainAuthSessionStore()
    private let budgetStore = EncryptedBudgetStore()
    private let categoryStore = EncryptedTransactionCategoryStore()
    private let onboardingStore = KeychainOnboardingProfileStore()
    private let receiptImageStore = EncryptedReceiptImageStore()
    private let transactionStore = EncryptedTransactionStore()

    var body: some Scene {
        WindowGroup {
            KasoRootView(
                appearanceSettingsRepository: appearanceStore.repository(),
                authRepository: authStore.repository(),
                budgetRepository: budgetStore.repository(),
                categoryRepository: categoryStore.repository(),
                onboardingProfileRepository: onboardingStore.repository(),
                receiptImageRepository: receiptImageStore.repository(),
                transactionRepository: transactionStore.repository()
            )
        }
    }
}
