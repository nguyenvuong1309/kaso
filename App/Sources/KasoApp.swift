import KasoRootFeature
import PersistenceKit
import SwiftUI

@main
struct KasoApp: App {
    private let authStore = KeychainAuthSessionStore()
    private let onboardingStore = KeychainOnboardingProfileStore()
    private let transactionStore = InMemoryTransactionStore()

    var body: some Scene {
        WindowGroup {
            KasoRootView(
                authRepository: authStore.repository(),
                onboardingProfileRepository: onboardingStore.repository(),
                transactionRepository: transactionStore.repository()
            )
        }
    }
}
