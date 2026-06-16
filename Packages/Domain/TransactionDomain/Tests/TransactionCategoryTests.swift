import Foundation
import Testing
@testable import TransactionDomain

@Test("category id drives identity")
func categoryIdDrivesIdentity() {
    #expect(TransactionCategory.food.id == "food")
    #expect(TransactionCategory.salary.id == "salary")
    #expect(TransactionCategory.other.id == "other")
}

@Test("default expense categories list is complete and ordered")
func defaultExpenseCategoriesList() {
    #expect(
        TransactionCategory.defaultExpenseCategories.map(\.id) == [
            "food",
            "transport",
            "housing",
            "entertainment",
            "health",
            "education",
            "shopping",
            "other",
        ]
    )
}

@Test("default income categories list is complete and ordered")
func defaultIncomeCategoriesList() {
    #expect(
        TransactionCategory.defaultIncomeCategories.map(\.id) == ["salary", "other"]
    )
}

@Test("defaults helper returns the matching set per kind")
func defaultsHelperPerKind() {
    #expect(TransactionCategory.defaults(for: .income) == TransactionCategory.defaultIncomeCategories)
    #expect(TransactionCategory.defaults(for: .expense) == TransactionCategory.defaultExpenseCategories)
}

@Test("default category helper picks the canonical category per kind")
func defaultCategoryPerKind() {
    #expect(TransactionCategory.defaultCategory(for: .income) == .salary)
    #expect(TransactionCategory.defaultCategory(for: .expense) == .food)
}

@Test("category metadata carries symbol and color names")
func categoryMetadata() {
    #expect(TransactionCategory.food.nameKey == "category.food")
    #expect(TransactionCategory.food.symbolName == "fork.knife")
    #expect(TransactionCategory.food.colorName == "mint")
    #expect(TransactionCategory.transport.symbolName == "bus")
    #expect(TransactionCategory.salary.colorName == "green")
}

@Test("category is hashable by full value")
func categoryHashable() {
    var set: Set<TransactionCategory> = []
    set.insert(.food)
    set.insert(.food)
    set.insert(.transport)

    #expect(set.count == 2)
    #expect(set.contains(.food))
    #expect(set.contains(.transport))
}

@Test("category round-trips through Codable")
func categoryCodableRoundTrip() throws {
    let data = try JSONEncoder().encode(TransactionCategory.shopping)
    let decoded = try JSONDecoder().decode(TransactionCategory.self, from: data)

    #expect(decoded == .shopping)
}

@Test("categories sharing an id but differing fields are not equal")
func categoryEqualityUsesAllFields() {
    let custom = TransactionCategory(
        id: "food",
        nameKey: "category.food.custom",
        symbolName: "fork.knife",
        colorName: "mint"
    )

    #expect(custom != TransactionCategory.food)
    #expect(custom.id == TransactionCategory.food.id)
}
