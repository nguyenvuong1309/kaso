import Charts
import SwiftUI
import KasoDesignSystem
import WealthDomain

struct NetWorthSummaryCard: View {
    let snapshot: NetWorthSnapshot
    let growth: NetWorthGrowth

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("wealth.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(snapshot.netWorth.formatted(.currency(code: "VND")))
                .font(.kaso.numericLarge)
                .foregroundStyle(snapshot.netWorth >= 0 ? Color.kaso.positive : Color.kaso.destructive)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            Text(growthText)
                .font(.kaso.caption)
                .foregroundStyle(growthColor)

            HStack(spacing: Spacing.sm) {
                WealthMetric(
                    titleKey: "wealth.summary.assets",
                    amount: snapshot.totalAssets,
                    symbolName: "plus.circle.fill",
                    color: Color.kaso.positive
                )
                WealthMetric(
                    titleKey: "wealth.summary.liabilities",
                    amount: snapshot.totalLiabilities,
                    symbolName: "minus.circle.fill",
                    color: Color.kaso.destructive
                )
            }
        }
    }

    private var growthText: String {
        guard growth.hasBaseline else {
            return String(localized: "wealth.growth.noBaseline", bundle: .module)
        }

        let amount = growth.absoluteDelta.formatted(.currency(code: "VND"))
        let percent = growth.percentDelta.formatted(.percent.precision(.fractionLength(0)))
        return "\(amount) · \(percent)"
    }

    private var growthColor: Color {
        if growth.isPositive {
            Color.kaso.positive
        } else if growth.isNegative {
            Color.kaso.destructive
        } else {
            Color.kaso.textSecondary
        }
    }
}

struct NetWorthHistoryCard: View {
    let history: [NetWorthSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("wealth.history.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if history.isEmpty {
                Text("wealth.history.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                Chart(history) { snapshot in
                    LineMark(
                        x: .value("wealth.history.month", snapshot.date),
                        y: .value("wealth.history.netWorth", amountValue(snapshot.netWorth))
                    )
                    .foregroundStyle(Color.kaso.accent)

                    AreaMark(
                        x: .value("wealth.history.month", snapshot.date),
                        y: .value("wealth.history.netWorth", amountValue(snapshot.netWorth))
                    )
                    .foregroundStyle(Color.kaso.accent.opacity(Layout.areaOpacity))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: Layout.axisDesiredCount)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: Layout.chartHeight)
            }
        }
    }
}

struct WealthBreakdownCard: View {
    let breakdown: NetWorthBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("wealth.breakdown.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            WealthBreakdownGroup(
                titleKey: "wealth.breakdown.assets",
                items: breakdown.assetItems
            )

            WealthBreakdownGroup(
                titleKey: "wealth.breakdown.liabilities",
                items: breakdown.liabilityItems
            )
        }
    }
}

private struct WealthMetric: View {
    let titleKey: String
    let amount: Decimal
    let symbolName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: symbolName)
                .foregroundStyle(color)

            Text(amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfaceSecondary)
        )
    }
}

private struct WealthBreakdownGroup: View {
    let titleKey: String
    let items: [NetWorthBreakdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            if items.isEmpty {
                Text("wealth.breakdown.empty", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(items.prefix(Layout.breakdownLimit)) { item in
                    WealthBreakdownRow(item: item)
                }
            }
        }
    }
}

private struct WealthBreakdownRow: View {
    let item: NetWorthBreakdownItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: item.symbolName)
                    .foregroundStyle(Color.kaso.category(named: item.colorName))
                Text(LocalizedStringKey(item.label), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer(minLength: Spacing.md)
                Text(item.amount.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)
            }

            ProgressView(value: item.fraction)
                .tint(Color.kaso.category(named: item.colorName))
        }
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let areaOpacity: Double = 0.18
    static let axisDesiredCount = 4
    static let breakdownLimit = 5
    static let chartHeight: CGFloat = 180
}

private func amountValue(_ amount: Decimal) -> Double {
    NSDecimalNumber(decimal: amount).doubleValue
}
