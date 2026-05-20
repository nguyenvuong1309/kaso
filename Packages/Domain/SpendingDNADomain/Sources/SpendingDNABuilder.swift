import Foundation

public struct SpendingDNATransactionInput: Equatable, Sendable {
    public let amount: Decimal
    public let categoryID: String
    public let isExpense: Bool
    public let occurredAt: Date

    public init(amount: Decimal, categoryID: String, isExpense: Bool, occurredAt: Date) {
        self.amount = amount
        self.categoryID = categoryID
        self.isExpense = isExpense
        self.occurredAt = occurredAt
    }
}

public enum SpendingDNABuilder {
    public static let minimumTransactionCount = 12

    private static let foodCategories: Set<String> = ["food", "dining", "coffee", "cafe", "anuong"]
    private static let exploreCategories: Set<String> = [
        "entertainment", "travel", "experience", "giaitri", "dulich",
    ]

    public static func build(
        transactions: [SpendingDNATransactionInput],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> SpendingDNAReport {
        let year = calendar.component(.year, from: referenceDate)
        let scoped = transactions.filter { calendar.component(.year, from: $0.occurredAt) == year }

        guard scoped.count >= minimumTransactionCount else {
            return SpendingDNAReport(
                year: year,
                totalIncome: 0,
                totalExpense: 0,
                savingsRate: 0,
                transactionCount: scoped.count,
                topCategories: [],
                largestTransaction: 0,
                mostActiveMonth: 0,
                bestSavingMonth: 0,
                type: .balanced,
                generatedAt: referenceDate,
                isSufficient: false
            )
        }

        let income = scoped.filter { !$0.isExpense }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = scoped.filter(\.isExpense).reduce(Decimal(0)) { $0 + $1.amount }
        let incomeDouble = NSDecimalNumber(decimal: income).doubleValue
        let expenseDouble = NSDecimalNumber(decimal: expense).doubleValue
        let savingsRate = incomeDouble > 0 ? (incomeDouble - expenseDouble) / incomeDouble : 0

        let categoryTotals = scoped
            .filter(\.isExpense)
            .reduce(into: [String: Decimal]()) { acc, item in
                acc[item.categoryID, default: 0] += item.amount
            }
        let topCategories = categoryTotals
            .map { categoryID, amount -> SpendingDNACategory in
                let percentage = expenseDouble > 0
                    ? NSDecimalNumber(decimal: amount).doubleValue / expenseDouble
                    : 0
                return SpendingDNACategory(
                    categoryID: categoryID,
                    totalAmount: amount,
                    percentage: percentage
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount }
        let top = Array(topCategories.prefix(3))

        let largest = scoped.filter(\.isExpense).map(\.amount).max() ?? 0
        let mostActiveMonth = monthWithMostTransactions(scoped, calendar: calendar)
        let bestSavingMonth = monthWithBestNet(scoped, calendar: calendar)
        let type = classify(
            savingsRate: savingsRate,
            dominantCategory: topCategories.first?.categoryID,
            dominantShare: topCategories.first?.percentage ?? 0
        )

        return SpendingDNAReport(
            year: year,
            totalIncome: income,
            totalExpense: expense,
            savingsRate: savingsRate,
            transactionCount: scoped.count,
            topCategories: top,
            largestTransaction: largest,
            mostActiveMonth: mostActiveMonth,
            bestSavingMonth: bestSavingMonth,
            type: type,
            generatedAt: referenceDate,
            isSufficient: true
        )
    }

    static func classify(
        savingsRate: Double,
        dominantCategory: String?,
        dominantShare: Double
    ) -> SpendingDNAType {
        if savingsRate >= 0.3 {
            return .saver
        }
        if savingsRate < 0 {
            return .spender
        }
        if let dominantCategory, dominantShare >= 0.35 {
            if foodCategories.contains(dominantCategory) {
                return .foodie
            }
            if exploreCategories.contains(dominantCategory) {
                return .explorer
            }
        }
        return .balanced
    }

    private static func monthWithMostTransactions(
        _ transactions: [SpendingDNATransactionInput],
        calendar: Calendar
    ) -> Int {
        let counts = transactions.reduce(into: [Int: Int]()) { acc, item in
            acc[calendar.component(.month, from: item.occurredAt), default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key ?? 0
    }

    private static func monthWithBestNet(
        _ transactions: [SpendingDNATransactionInput],
        calendar: Calendar
    ) -> Int {
        let net = transactions.reduce(into: [Int: Decimal]()) { acc, item in
            let month = calendar.component(.month, from: item.occurredAt)
            acc[month, default: 0] += item.isExpense ? -item.amount : item.amount
        }
        return net.max { $0.value < $1.value }?.key ?? 0
    }
}
