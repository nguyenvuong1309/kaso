import Foundation
import PersistenceKit
import TransactionDomain

public enum QuickEntryIntentEnvironment {
    @TaskLocal public static var transactionRepositoryOverride: TransactionRepository?
    @TaskLocal public static var categoryRepositoryOverride: TransactionCategoryRepository?

    public static var transactionRepository: TransactionRepository {
        transactionRepositoryOverride ?? EncryptedTransactionStore().repository()
    }

    public static var categoryRepository: TransactionCategoryRepository {
        categoryRepositoryOverride ?? EncryptedTransactionCategoryStore().repository()
    }

    static func loadCustomCategories() async -> [TransactionCategory] {
        (try? await categoryRepository.fetchCustomCategories()) ?? []
    }
}
