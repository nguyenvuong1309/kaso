import Foundation

public struct TransactionCategory: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public var nameKey: String
    public var symbolName: String
    public var colorName: String

    public init(
        id: String,
        nameKey: String,
        symbolName: String,
        colorName: String
    ) {
        self.id = id
        self.nameKey = nameKey
        self.symbolName = symbolName
        self.colorName = colorName
    }
}

public extension TransactionCategory {
    static let food = TransactionCategory(
        id: "food",
        nameKey: "category.food",
        symbolName: "fork.knife",
        colorName: "mint"
    )

    static let transport = TransactionCategory(
        id: "transport",
        nameKey: "category.transport",
        symbolName: "bus",
        colorName: "blue"
    )

    static let housing = TransactionCategory(
        id: "housing",
        nameKey: "category.housing",
        symbolName: "house",
        colorName: "indigo"
    )

    static let entertainment = TransactionCategory(
        id: "entertainment",
        nameKey: "category.entertainment",
        symbolName: "sparkles.tv",
        colorName: "purple"
    )

    static let health = TransactionCategory(
        id: "health",
        nameKey: "category.health",
        symbolName: "cross.case",
        colorName: "red"
    )

    static let education = TransactionCategory(
        id: "education",
        nameKey: "category.education",
        symbolName: "book",
        colorName: "brown"
    )

    static let shopping = TransactionCategory(
        id: "shopping",
        nameKey: "category.shopping",
        symbolName: "bag",
        colorName: "pink"
    )

    static let salary = TransactionCategory(
        id: "salary",
        nameKey: "category.salary",
        symbolName: "banknote",
        colorName: "green"
    )

    static let other = TransactionCategory(
        id: "other",
        nameKey: "category.other",
        symbolName: "ellipsis.circle",
        colorName: "gray"
    )

    static let defaultExpenseCategories: [TransactionCategory] = [
        .food,
        .transport,
        .housing,
        .entertainment,
        .health,
        .education,
        .shopping,
        .other,
    ]

    static let defaultIncomeCategories: [TransactionCategory] = [
        .salary,
        .other,
    ]

    static func defaults(for kind: TransactionKind) -> [TransactionCategory] {
        switch kind {
        case .income:
            defaultIncomeCategories
        case .expense:
            defaultExpenseCategories
        }
    }

    static func defaultCategory(for kind: TransactionKind) -> TransactionCategory {
        switch kind {
        case .income:
            .salary
        case .expense:
            .food
        }
    }
}
