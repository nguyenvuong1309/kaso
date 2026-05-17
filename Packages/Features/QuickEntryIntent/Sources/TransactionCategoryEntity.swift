import AppIntents
import Foundation
import TransactionDomain

public struct TransactionCategoryEntity: AppEntity, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Danh mục")

    public static let defaultQuery = ExpenseCategoryQuery()

    public let id: String
    public let storedName: String
    public let symbolName: String

    public init(id: String, storedName: String, symbolName: String) {
        self.id = id
        self.storedName = storedName
        self.symbolName = symbolName
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(localized: localizedName))",
            image: .init(systemName: symbolName)
        )
    }

    public func toDomain() -> TransactionCategory {
        TransactionCategory(
            id: id,
            nameKey: storedName,
            symbolName: symbolName,
            colorName: Self.defaultColorName(for: id)
        )
    }

    var localizedName: LocalizedStringResource {
        switch id {
        case "food": LocalizedStringResource("category.food", defaultValue: "Ăn uống")
        case "transport": LocalizedStringResource("category.transport", defaultValue: "Di chuyển")
        case "housing": LocalizedStringResource("category.housing", defaultValue: "Nhà ở")
        case "entertainment": LocalizedStringResource("category.entertainment", defaultValue: "Giải trí")
        case "health": LocalizedStringResource("category.health", defaultValue: "Sức khoẻ")
        case "education": LocalizedStringResource("category.education", defaultValue: "Giáo dục")
        case "shopping": LocalizedStringResource("category.shopping", defaultValue: "Mua sắm")
        case "salary": LocalizedStringResource("category.salary", defaultValue: "Lương")
        case "other": LocalizedStringResource("category.other", defaultValue: "Khác")
        default: LocalizedStringResource(stringLiteral: storedName)
        }
    }

    static func defaultColorName(for id: String) -> String {
        switch id {
        case "food": "mint"
        case "transport": "blue"
        case "housing": "indigo"
        case "entertainment": "purple"
        case "health": "red"
        case "education": "brown"
        case "shopping": "pink"
        case "salary": "green"
        default: "gray"
        }
    }
}

public extension TransactionCategoryEntity {
    init(_ category: TransactionCategory) {
        self.init(
            id: category.id,
            storedName: category.nameKey,
            symbolName: category.symbolName
        )
    }
}

public struct IncomeCategoryEntity: AppEntity, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Danh mục thu nhập")

    public static let defaultQuery = IncomeCategoryQuery()

    public let id: String
    public let storedName: String
    public let symbolName: String

    public init(id: String, storedName: String, symbolName: String) {
        self.id = id
        self.storedName = storedName
        self.symbolName = symbolName
    }

    public init(_ category: TransactionCategory) {
        self.init(id: category.id, storedName: category.nameKey, symbolName: category.symbolName)
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(localized: localizedName))",
            image: .init(systemName: symbolName)
        )
    }

    public func toDomain() -> TransactionCategory {
        TransactionCategory(
            id: id,
            nameKey: storedName,
            symbolName: symbolName,
            colorName: TransactionCategoryEntity.defaultColorName(for: id)
        )
    }

    var localizedName: LocalizedStringResource {
        switch id {
        case "salary": LocalizedStringResource("category.salary", defaultValue: "Lương")
        case "other": LocalizedStringResource("category.other", defaultValue: "Khác")
        default: LocalizedStringResource(stringLiteral: storedName)
        }
    }
}
