import AppIntents
import Foundation
import TransactionDomain

public struct ExpenseCategoryQuery: EntityQuery, EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [TransactionCategoryEntity.ID]) async throws -> [TransactionCategoryEntity] {
        let all = await allCategories()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    public func suggestedEntities() async throws -> [TransactionCategoryEntity] {
        await allCategories()
    }

    public func entities(matching string: String) async throws -> [TransactionCategoryEntity] {
        let normalized = string.lowercased()
        return await allCategories().filter { entity in
            let title = String(localized: entity.localizedName).lowercased()
            return title.contains(normalized) || entity.storedName.lowercased().contains(normalized)
        }
    }

    private func allCategories() async -> [TransactionCategoryEntity] {
        let defaults = TransactionCategory.defaultExpenseCategories.map(TransactionCategoryEntity.init)
        let custom = await QuickEntryIntentEnvironment.loadCustomCategories()
            .map(TransactionCategoryEntity.init)
        return defaults + custom.filter { entity in
            defaults.contains(where: { $0.id == entity.id }) == false
        }
    }
}

public struct IncomeCategoryQuery: EntityQuery, EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [IncomeCategoryEntity.ID]) async throws -> [IncomeCategoryEntity] {
        let all = await allCategories()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    public func suggestedEntities() async throws -> [IncomeCategoryEntity] {
        await allCategories()
    }

    public func entities(matching string: String) async throws -> [IncomeCategoryEntity] {
        let normalized = string.lowercased()
        return await allCategories().filter { entity in
            let title = String(localized: entity.localizedName).lowercased()
            return title.contains(normalized) || entity.storedName.lowercased().contains(normalized)
        }
    }

    private func allCategories() async -> [IncomeCategoryEntity] {
        TransactionCategory.defaultIncomeCategories.map(IncomeCategoryEntity.init)
    }
}
