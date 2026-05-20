import Foundation

public enum SpendingDNAType: String, Codable, Equatable, Sendable, CaseIterable {
    case saver
    case foodie
    case explorer
    case spender
    case balanced

    public var emoji: String {
        switch self {
        case .saver: "🪙"
        case .foodie: "🍜"
        case .explorer: "🧭"
        case .spender: "💸"
        case .balanced: "⚖️"
        }
    }

    public var titleKey: String { "dna.type.\(rawValue).title" }
    public var taglineKey: String { "dna.type.\(rawValue).tagline" }
}

public struct SpendingDNACategory: Identifiable, Equatable, Sendable {
    public let id: String
    public let categoryID: String
    public let totalAmount: Decimal
    public let percentage: Double // 0-1

    public init(categoryID: String, totalAmount: Decimal, percentage: Double) {
        id = categoryID
        self.categoryID = categoryID
        self.totalAmount = totalAmount
        self.percentage = percentage
    }
}

public struct SpendingDNAReport: Equatable, Sendable {
    public let year: Int
    public let totalIncome: Decimal
    public let totalExpense: Decimal
    public let savingsRate: Double // can be negative
    public let transactionCount: Int
    public let topCategories: [SpendingDNACategory]
    public let largestTransaction: Decimal
    public let mostActiveMonth: Int // 1-12, 0 when unknown
    public let bestSavingMonth: Int // 1-12, 0 when unknown
    public let type: SpendingDNAType
    public let generatedAt: Date
    public let isSufficient: Bool

    public init(
        year: Int,
        totalIncome: Decimal,
        totalExpense: Decimal,
        savingsRate: Double,
        transactionCount: Int,
        topCategories: [SpendingDNACategory],
        largestTransaction: Decimal,
        mostActiveMonth: Int,
        bestSavingMonth: Int,
        type: SpendingDNAType,
        generatedAt: Date,
        isSufficient: Bool
    ) {
        self.year = year
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.savingsRate = savingsRate
        self.transactionCount = transactionCount
        self.topCategories = topCategories
        self.largestTransaction = largestTransaction
        self.mostActiveMonth = mostActiveMonth
        self.bestSavingMonth = bestSavingMonth
        self.type = type
        self.generatedAt = generatedAt
        self.isSufficient = isSufficient
    }

    public static let empty = SpendingDNAReport(
        year: 0,
        totalIncome: 0,
        totalExpense: 0,
        savingsRate: 0,
        transactionCount: 0,
        topCategories: [],
        largestTransaction: 0,
        mostActiveMonth: 0,
        bestSavingMonth: 0,
        type: .balanced,
        generatedAt: Date(timeIntervalSinceReferenceDate: 0),
        isSufficient: false
    )
}
