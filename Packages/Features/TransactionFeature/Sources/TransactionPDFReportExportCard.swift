import CoreGraphics
import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import InsightDomain
import KasoDesignSystem
import TransactionDomain

struct TransactionPDFReportExportCard: View {
    let report: TransactionPDFReport
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("transactions.pdfExport.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Text("transactions.pdfExport.description", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            HStack(spacing: Spacing.md) {
                Label {
                    Text(report.transactionCount.formatted())
                        .font(.kaso.numericMedium)
                } icon: {
                    Image(systemName: "doc.richtext")
                }
                .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                if isDisabled {
                    Label {
                        Text("transactions.export.empty", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                } else {
                    ShareLink(
                        item: TransactionPDFReportTransferable(report: report),
                        preview: SharePreview(report.fileName)
                    ) {
                        Label {
                            Text("transactions.pdfExport.share", bundle: .module)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .font(.kaso.body)
                }
            }
        }
    }
}

struct TransactionPDFReportTransferable: Transferable {
    let report: TransactionPDFReport

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            try await MainActor.run {
                try TransactionPDFReportRenderer.render(item.report)
            }
        }
    }
}

private enum TransactionPDFReportRenderer {
    @MainActor
    static func render(_ report: TransactionPDFReport) throws -> Data {
        let pageSize = CGSize(width: PDFReportLayout.pageWidth, height: PDFReportLayout.pageHeight)
        let renderer = ImageRenderer(content: TransactionPDFReportPage(report: report))
        renderer.proposedSize = ProposedViewSize(pageSize)

        let data = NSMutableData()
        renderer.render { _, render in
            var mediaBox = CGRect(origin: .zero, size: pageSize)
            guard
                let consumer = CGDataConsumer(data: data as CFMutableData),
                let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else {
                return
            }

            context.beginPDFPage(nil)
            render(context)
            context.endPDFPage()
            context.closePDF()
        }

        guard data.length > 0 else {
            throw TransactionPDFReportRenderingError.contextCreationFailed
        }

        return data as Data
    }
}

private enum TransactionPDFReportRenderingError: Error {
    case contextCreationFailed
}

private struct TransactionPDFReportPage: View {
    let report: TransactionPDFReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header
            summaryGrid
            categorySection
            insightSection
            recentTransactionSection
            Spacer(minLength: Spacing.sm)
            footer
        }
        .padding(Spacing.xl)
        .frame(
            width: PDFReportLayout.pageWidth,
            height: PDFReportLayout.pageHeight,
            alignment: .topLeading
        )
        .background(Color.kaso.surfacePrimary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Kaso")
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.accent)

            Text("transactions.pdfReport.title", bundle: .module)
                .font(.kaso.titleLarge)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(periodText)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
    }

    private var summaryGrid: some View {
        HStack(spacing: Spacing.md) {
            PDFReportMetric(
                titleKey: "transactions.summary.income",
                amount: report.summary.income,
                symbolName: "arrow.down.circle.fill",
                color: Color.kaso.positive
            )
            PDFReportMetric(
                titleKey: "transactions.summary.expense",
                amount: report.summary.expense,
                symbolName: "arrow.up.circle.fill",
                color: Color.kaso.destructive
            )
            PDFReportMetric(
                titleKey: "transactions.summary.balance",
                amount: report.summary.balance,
                symbolName: "equal.circle.fill",
                color: Color.kaso.accent
            )
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("transactions.pdfReport.categories", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if report.categorySpendings.isEmpty {
                Text("transactions.pdfReport.categories.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(Array(report.categorySpendings.prefix(PDFReportLayout.categoryLimit))) {
                        PDFReportCategoryRow(spending: $0)
                    }
                }
            }
        }
    }

    private var insightSection: some View {
        HStack(spacing: Spacing.md) {
            PDFReportComparisonCard(
                titleKey: "transactions.report.month",
                comparison: report.comparisonReport.month
            )
            PDFReportComparisonCard(
                titleKey: "transactions.report.year",
                comparison: report.comparisonReport.yearToDate
            )
            PDFReportForecastCard(forecast: report.balanceForecast)
        }
    }

    private var recentTransactionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("transactions.pdfReport.recentTransactions", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if report.recentTransactions.isEmpty {
                Text("transactions.pdfReport.recentTransactions.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(report.recentTransactions.prefix(PDFReportLayout.transactionLimit)) {
                        PDFReportTransactionRow(transaction: $0)
                    }
                }
            }
        }
    }

    private var footer: some View {
        Text("transactions.pdfReport.footer", bundle: .module)
            .font(.kaso.caption)
            .foregroundStyle(Color.kaso.textSecondary)
    }

    private var periodText: String {
        let start = report.periodStart.formatted(.dateTime.day().month(.wide).year())
        let end = report.periodEnd.formatted(.dateTime.day().month(.wide).year())
        return "\(start) – \(end)"
    }
}

private struct PDFReportMetric: View {
    let titleKey: String
    let amount: Decimal
    let symbolName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: symbolName)
                .foregroundStyle(color)

            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(PDFReportLayout.minimumScaleFactor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfaceSecondary)
        )
    }
}

private struct PDFReportCategoryRow: View {
    let spending: MonthlyCategorySpending

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: spending.category.symbolName)
                    .foregroundStyle(Color.kaso.category(named: spending.category.colorName))

                Text(LocalizedStringKey(spending.category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                Text(spending.amount.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            GeometryReader { proxy in
                Capsule()
                    .fill(Color.kaso.surfaceSecondary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.kaso.category(named: spending.category.colorName))
                            .frame(width: proxy.size.width * boundedFraction)
                    }
            }
            .frame(height: Spacing.sm)
        }
    }

    private var boundedFraction: Double {
        min(max(spending.fraction, 0), 1)
    }
}

private struct PDFReportComparisonCard: View {
    let titleKey: String
    let comparison: SpendingPeriodComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(comparison.currentExpense.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Label {
                Text(deltaText)
            } icon: {
                Image(systemName: comparison.trend.pdfSymbolName)
            }
            .font(.kaso.caption)
            .foregroundStyle(comparison.trend.pdfColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfaceSecondary)
        )
    }

    private var deltaText: String {
        let amount = comparison.delta.formatted(.currency(code: "VND"))
        guard let percentageChange = comparison.percentageChange else {
            return amount
        }

        let percent = percentageChange.formatted(.percent.precision(.fractionLength(0)))
        return "\(amount) · \(percent)"
    }
}

private struct PDFReportForecastCard: View {
    let forecast: MonthlyBalanceForecast

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("transactions.pdfReport.forecast", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(forecast.projectedBalance.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(LocalizedStringKey(forecast.status.titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(forecast.status.pdfColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfaceSecondary)
        )
    }
}

private struct PDFReportTransactionRow: View {
    let transaction: TransactionDomain.Transaction

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(transaction.occurredAt.formatted(.dateTime.day().month()))
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .frame(width: PDFReportLayout.dateColumnWidth, alignment: .leading)

            Text(LocalizedStringKey(transaction.category.nameKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Spacer(minLength: Spacing.md)

            Text(transaction.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(transaction.kind.pdfAmountColor)
        }
        .padding(.vertical, Spacing.xs)
    }
}

private extension TransactionKind {
    var pdfAmountColor: Color {
        switch self {
        case .income:
            Color.kaso.positive
        case .expense:
            Color.kaso.destructive
        }
    }
}

private extension SpendingComparisonTrend {
    var pdfSymbolName: String {
        switch self {
        case .increased:
            "arrow.up.right"
        case .decreased:
            "arrow.down.right"
        case .flat:
            "minus"
        }
    }

    var pdfColor: Color {
        switch self {
        case .increased:
            Color.kaso.destructive
        case .decreased:
            Color.kaso.positive
        case .flat:
            Color.kaso.textSecondary
        }
    }
}

private extension MonthlyBalanceForecastStatus {
    var pdfColor: Color {
        switch self {
        case .safe:
            Color.kaso.positive
        case .tight:
            Color.kaso.warning
        case .negative:
            Color.kaso.destructive
        }
    }
}

private enum PDFReportLayout {
    static let pageWidth: CGFloat = 595
    static let pageHeight: CGFloat = 842
    static let categoryLimit = 5
    static let transactionLimit = 8
    static let dateColumnWidth: CGFloat = 56
    static let minimumScaleFactor: CGFloat = 0.72
}
