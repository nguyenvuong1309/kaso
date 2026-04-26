import Foundation
import SwiftUI
import InsightDomain
import KasoDesignSystem
import TransactionDomain

#Preview("PDF Export Card Light") {
    KasoCard {
        TransactionPDFReportExportCard(
            report: .preview,
            isDisabled: false
        )
    }
    .padding(Spacing.md)
}

#Preview("PDF Export Card Dark") {
    KasoCard {
        TransactionPDFReportExportCard(
            report: .preview,
            isDisabled: false
        )
    }
    .padding(Spacing.md)
    .preferredColorScheme(.dark)
}

#Preview("PDF Export Card Dynamic Type XL") {
    KasoCard {
        TransactionPDFReportExportCard(
            report: .preview,
            isDisabled: false
        )
    }
    .padding(Spacing.md)
    .environment(\.dynamicTypeSize, .accessibility1)
}

private extension TransactionPDFReport {
    static let preview = TransactionPDFReport(
        fileName: "kaso-report-preview.pdf",
        referenceDate: Date(timeIntervalSinceReferenceDate: 799_200_000),
        periodStart: Date(timeIntervalSinceReferenceDate: 797_040_000),
        periodEnd: Date(timeIntervalSinceReferenceDate: 799_631_999),
        summary: MonthlyTransactionSummary(
            income: 24_000_000,
            expense: 8_500_000,
            balance: 15_500_000
        ),
        categorySpendings: [
            MonthlyCategorySpending(category: .food, amount: 3_200_000, fraction: 0.38),
            MonthlyCategorySpending(category: .transport, amount: 1_800_000, fraction: 0.21),
            MonthlyCategorySpending(category: .shopping, amount: 1_400_000, fraction: 0.16),
        ],
        comparisonReport: SpendingComparisonReport(
            month: SpendingPeriodComparison(
                currentExpense: 8_500_000,
                previousExpense: 9_200_000,
                delta: -700_000,
                percentageChange: -0.08,
                trend: .decreased
            ),
            yearToDate: SpendingPeriodComparison(
                currentExpense: 38_000_000,
                previousExpense: 41_000_000,
                delta: -3_000_000,
                percentageChange: -0.07,
                trend: .decreased
            )
        ),
        balanceForecast: MonthlyBalanceForecast(
            incomeToDate: 24_000_000,
            expenseToDate: 8_500_000,
            projectedExpense: 10_200_000,
            projectedBalance: 13_800_000,
            dailyExpenseRate: 340_000,
            remainingDayCount: 5,
            status: .safe
        ),
        recentTransactions: [
            TransactionDomain.Transaction(
                amount: 120_000,
                kind: .expense,
                category: .food,
                occurredAt: Date(timeIntervalSinceReferenceDate: 799_200_000)
            ),
            TransactionDomain.Transaction(
                amount: 24_000_000,
                kind: .income,
                category: .salary,
                occurredAt: Date(timeIntervalSinceReferenceDate: 797_126_400)
            ),
        ],
        transactionCount: 18
    )
}
