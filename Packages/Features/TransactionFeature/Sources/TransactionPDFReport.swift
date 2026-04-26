import Foundation
import InsightDomain
import TransactionDomain

public struct TransactionPDFReport: Equatable, Sendable {
    public let fileName: String
    public let referenceDate: Date
    public let periodStart: Date
    public let periodEnd: Date
    public let summary: MonthlyTransactionSummary
    public let categorySpendings: [MonthlyCategorySpending]
    public let comparisonReport: SpendingComparisonReport
    public let balanceForecast: MonthlyBalanceForecast
    public let recentTransactions: [Transaction]
    public let transactionCount: Int

    public init(
        fileName: String,
        referenceDate: Date,
        periodStart: Date,
        periodEnd: Date,
        summary: MonthlyTransactionSummary,
        categorySpendings: [MonthlyCategorySpending],
        comparisonReport: SpendingComparisonReport,
        balanceForecast: MonthlyBalanceForecast,
        recentTransactions: [Transaction],
        transactionCount: Int
    ) {
        self.fileName = fileName
        self.referenceDate = referenceDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.summary = summary
        self.categorySpendings = categorySpendings
        self.comparisonReport = comparisonReport
        self.balanceForecast = balanceForecast
        self.recentTransactions = recentTransactions
        self.transactionCount = transactionCount
    }
}

public extension TransactionFeature.State {
    var pdfReport: TransactionPDFReport {
        let calendar = Calendar.current
        let period = calendar.dateInterval(of: .month, for: historyReferenceDate)
        let periodStart = period?.start ?? historyReferenceDate
        let periodEnd = period?.end.addingTimeInterval(-1) ?? historyReferenceDate
        let transactionArray = Array(transactions)
        let monthlyTransactions = transactionArray.filter {
            calendar.isDate($0.occurredAt, equalTo: historyReferenceDate, toGranularity: .month)
        }
        let recentTransactions = monthlyTransactions
            .sorted {
                if $0.occurredAt == $1.occurredAt {
                    $0.id.uuidString < $1.id.uuidString
                } else {
                    $0.occurredAt > $1.occurredAt
                }
            }
            .prefix(Self.pdfReportRecentTransactionLimit)

        return TransactionPDFReport(
            fileName: "kaso-report-\(Self.pdfReportDateString(historyReferenceDate)).pdf",
            referenceDate: historyReferenceDate,
            periodStart: periodStart,
            periodEnd: periodEnd,
            summary: monthlyTransactions.monthlySummary(
                containing: historyReferenceDate,
                calendar: calendar
            ),
            categorySpendings: monthlyTransactions.monthlyCategorySpendings(
                containing: historyReferenceDate,
                calendar: calendar
            ),
            comparisonReport: SpendingComparisonReporter.report(
                transactions: transactionArray,
                referenceDate: historyReferenceDate,
                calendar: calendar
            ),
            balanceForecast: MonthlyBalanceForecaster.forecast(
                transactions: transactionArray,
                referenceDate: historyReferenceDate,
                calendar: calendar
            ),
            recentTransactions: Array(recentTransactions),
            transactionCount: monthlyTransactions.count
        )
    }

    private static var pdfReportRecentTransactionLimit: Int {
        12
    }

    private static func pdfReportDateString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
