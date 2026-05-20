import Foundation

public enum WrappedScope: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case month
    case year

    public var id: String { rawValue }

    public var titleKey: String { "wrapped.scope.\(rawValue).title" }
}

public struct WrappedTopCategory: Identifiable, Equatable, Sendable {
    public let id: String
    public let categoryID: String
    public let totalAmount: Decimal
    public let percentage: Double  // 0-1
    public let transactionCount: Int

    public init(categoryID: String, totalAmount: Decimal, percentage: Double, transactionCount: Int) {
        id = categoryID
        self.categoryID = categoryID
        self.totalAmount = totalAmount
        self.percentage = percentage
        self.transactionCount = transactionCount
    }
}

public struct WrappedReport: Equatable, Sendable {
    public let scope: WrappedScope
    public let periodLabel: String  // "Tháng 5/2026" hoặc "2026"
    public let totalIncome: Decimal
    public let totalExpense: Decimal
    public let netBalance: Decimal
    public let transactionCount: Int
    public let topCategories: [WrappedTopCategory]
    public let largestTransaction: Decimal
    public let noSpendDays: Int
    public let bestStreak: Int
    public let generatedAt: Date
    public let isSufficient: Bool

    public init(
        scope: WrappedScope,
        periodLabel: String,
        totalIncome: Decimal,
        totalExpense: Decimal,
        netBalance: Decimal,
        transactionCount: Int,
        topCategories: [WrappedTopCategory],
        largestTransaction: Decimal,
        noSpendDays: Int,
        bestStreak: Int,
        generatedAt: Date,
        isSufficient: Bool
    ) {
        self.scope = scope
        self.periodLabel = periodLabel
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.netBalance = netBalance
        self.transactionCount = transactionCount
        self.topCategories = topCategories
        self.largestTransaction = largestTransaction
        self.noSpendDays = noSpendDays
        self.bestStreak = bestStreak
        self.generatedAt = generatedAt
        self.isSufficient = isSufficient
    }

    public static let empty = WrappedReport(
        scope: .month,
        periodLabel: "",
        totalIncome: 0,
        totalExpense: 0,
        netBalance: 0,
        transactionCount: 0,
        topCategories: [],
        largestTransaction: 0,
        noSpendDays: 0,
        bestStreak: 0,
        generatedAt: Date(timeIntervalSinceReferenceDate: 0),
        isSufficient: false
    )
}
