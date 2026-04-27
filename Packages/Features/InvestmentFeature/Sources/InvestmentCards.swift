import SwiftUI
import InvestmentDomain
import KasoDesignSystem

struct InvestmentSummaryCard: View {
    let metrics: PortfolioMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("investment.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(metrics.marketValue.formatted(.currency(code: "VND")))
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            LazyVGrid(columns: Layout.summaryColumns, alignment: .leading, spacing: Spacing.md) {
                InvestmentMetricBlock(
                    titleKey: "investment.summary.cost",
                    value: metrics.totalCost.formatted(.currency(code: "VND")),
                    color: Color.kaso.textSecondary
                )
                InvestmentMetricBlock(
                    titleKey: "investment.summary.pl",
                    value: metrics.unrealizedPL.formatted(.currency(code: "VND")),
                    color: metrics.unrealizedPL >= 0 ? Color.kaso.positive : Color.kaso.destructive
                )
                InvestmentMetricBlock(
                    titleKey: "investment.summary.plPercent",
                    value: metrics.unrealizedPLPercent.formatted(.percent.precision(.fractionLength(1))),
                    color: metrics.unrealizedPL >= 0 ? Color.kaso.positive : Color.kaso.destructive
                )
                InvestmentMetricBlock(
                    titleKey: "investment.summary.coverage",
                    value: "\(metrics.coveredHoldingCount)/\(metrics.totalHoldingCount)",
                    color: metrics.hasMissingQuotes ? Color.kaso.warning : Color.kaso.positive
                )
            }
        }
    }
}

struct InvestmentAllocationCard: View {
    let breakdown: AllocationBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("investment.allocation.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if breakdown.slices.isEmpty {
                Text("investment.allocation.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(breakdown.slices) { slice in
                    InvestmentAllocationRow(slice: slice)
                }
            }
        }
    }
}

struct InvestmentRebalanceCard: View {
    let target: TargetAllocation
    let suggestion: RebalanceSuggestion
    let onEditTargetTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("investment.rebalance.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                Button {
                    onEditTargetTapped()
                } label: {
                    Text("investment.target.edit", bundle: .module)
                }
                .font(.kaso.caption)
            }

            if target.fractions.isEmpty {
                Text("investment.rebalance.noTarget", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else if suggestion.actions.isEmpty {
                Label {
                    Text("investment.rebalance.balanced", bundle: .module)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.kaso.positive)
                }
                .font(.kaso.body)
            } else {
                ForEach(suggestion.actions) { action in
                    InvestmentRebalanceActionRow(action: action)
                }
            }
        }
    }
}

struct InvestmentHoldingSection: View {
    let holdings: [Holding]
    let metrics: [HoldingMetrics]
    let onAddTapped: () -> Void
    let onEditTapped: (Holding) -> Void
    let onDeleteTapped: (Holding) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("investment.holding.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                Button {
                    onAddTapped()
                } label: {
                    Label {
                        Text("investment.holding.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .font(.kaso.caption)
            }

            if holdings.isEmpty {
                Text("investment.holding.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(holdings) { holding in
                    InvestmentHoldingRow(
                        holding: holding,
                        metrics: metricMap[holding.id],
                        onEditTapped: {
                            onEditTapped(holding)
                        },
                        onDeleteTapped: {
                            onDeleteTapped(holding)
                        }
                    )
                }
            }
        }
    }

    private var metricMap: [UUID: HoldingMetrics] {
        metrics.reduce(into: [UUID: HoldingMetrics]()) { partial, metric in
            partial[metric.id] = metric
        }
    }
}

private struct InvestmentMetricBlock: View {
    let titleKey: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)
        }
    }
}

private struct InvestmentAllocationRow: View {
    let slice: AllocationSlice

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label {
                    Text(LocalizedStringKey(slice.assetClass.nameKey), bundle: .module)
                } icon: {
                    Image(systemName: slice.assetClass.symbolName)
                        .foregroundStyle(Color.kaso.category(named: slice.assetClass.colorName))
                }
                .font(.kaso.body)

                Spacer(minLength: Spacing.md)

                Text(slice.fraction.formatted(.percent.precision(.fractionLength(0))))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.kaso.surfacePrimary)
                    Capsule()
                        .fill(Color.kaso.category(named: slice.assetClass.colorName))
                        .frame(width: proxy.size.width * max(0, min(slice.fraction, 1)))
                }
            }
            .frame(height: Layout.progressHeight)
        }
    }
}

private struct InvestmentRebalanceActionRow: View {
    let action: RebalanceAction

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: action.kind == .buy ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundStyle(action.kind == .buy ? Color.kaso.positive : Color.kaso.warning)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(action.assetClass.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(
                    LocalizedStringKey(action.kind == .buy ? "investment.rebalance.buy" : "investment.rebalance.sell"),
                    bundle: .module
                )
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            Text(action.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
    }
}

private struct InvestmentHoldingRow: View {
    let holding: Holding
    let metrics: HoldingMetrics?
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: holding.assetClass.symbolName)
                .foregroundStyle(Color.kaso.category(named: holding.assetClass.colorName))
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(holding.symbol)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(holding.name)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text((metrics?.marketValue ?? holding.totalCost).formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)
                Text((metrics?.unrealizedPL ?? 0).formatted(.currency(code: "VND")))
                    .font(.kaso.caption)
                    .foregroundStyle((metrics?.unrealizedPL ?? 0) >= 0 ? Color.kaso.positive : Color.kaso.destructive)
            }

            Menu {
                Button {
                    onEditTapped()
                } label: {
                    Text("investment.row.edit", bundle: .module)
                }
                Button(role: .destructive) {
                    onDeleteTapped()
                } label: {
                    Text("investment.row.delete", bundle: .module)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
    static let progressHeight: CGFloat = 8
    static let summaryColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
}
