import SwiftUI
import InsightDomain
import KasoDesignSystem

struct BenchmarkSummaryCard: View {
    let report: AnonymousBenchmarkReport

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("benchmark.summary.title", bundle: .module)
                            .font(.kaso.titleMedium)
                            .foregroundStyle(Color.kaso.textPrimary)

                        Text(LocalizedStringKey(report.overallStatus.titleKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(report.overallStatus.tintColor)
                    }

                    Spacer()

                    Text("\(report.overallPeerPercentile)%")
                        .font(.kaso.numericLarge)
                        .foregroundStyle(report.overallStatus.tintColor)
                }

                HStack(spacing: Spacing.sm) {
                    BenchmarkMetric(
                        titleKey: "benchmark.summary.you",
                        amount: report.totalUserExpense,
                        color: Color.kaso.textPrimary
                    )
                    BenchmarkMetric(
                        titleKey: "benchmark.summary.median",
                        amount: report.totalBenchmarkExpense,
                        color: Color.kaso.accent
                    )
                }

                Label {
                    Text("benchmark.privacy.note", bundle: .module)
                } icon: {
                    Image(systemName: "person.2.slash")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }
}

struct BenchmarkComparisonList: View {
    let comparisons: [AnonymousBenchmarkCategoryComparison]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("benchmark.categories.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(comparisons.prefix(6)) { comparison in
                BenchmarkComparisonRow(comparison: comparison)
            }
        }
    }
}

private struct BenchmarkMetric: View {
    let titleKey: String
    let amount: Decimal
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            Color.kaso.surfacePrimary,
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
    }
}

private struct BenchmarkComparisonRow: View {
    let comparison: AnonymousBenchmarkCategoryComparison

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: comparison.category.symbolName)
                    .foregroundStyle(Color.kaso.category(named: comparison.category.colorName))

                Text(LocalizedStringKey(comparison.category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer()

                Text(LocalizedStringKey(comparison.status.titleKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(comparison.status.tintColor)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.kaso.surfaceSecondary)

                    Capsule()
                        .fill(comparison.status.tintColor.opacity(0.72))
                        .frame(width: barWidth(proxy.size.width))
                }
            }
            .frame(height: 8)

            HStack {
                Text(comparison.userAmount.formatted(.currency(code: "VND")))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer()

                Text(comparison.benchmarkAmount.formatted(.currency(code: "VND")))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(
            Color.kaso.surfacePrimary,
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
    }

    private func barWidth(_ availableWidth: CGFloat) -> CGFloat {
        guard comparison.benchmarkAmount > 0 else {
            return availableWidth * 0.5
        }

        let ratio = NSDecimalNumber(
            decimal: comparison.userAmount / comparison.benchmarkAmount
        ).doubleValue
        return availableWidth * min(1, max(0.05, ratio / 2))
    }
}

extension AnonymousBenchmarkStatus {
    var tintColor: Color {
        switch self {
        case .belowMedian:
            Color.kaso.positive
        case .nearMedian:
            Color.kaso.accent
        case .aboveMedian:
            Color.kaso.warning
        }
    }
}
