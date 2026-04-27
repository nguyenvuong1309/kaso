import SwiftUI
import KasoDesignSystem
import SleepCorrelationDomain

struct SleepPermissionBanner: View {
    let onRequest: () -> Void

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label {
                    Text("sleep.permission.title", bundle: .module)
                } icon: {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Color.kaso.accent)
                }
                .font(.kaso.titleMedium)

                Text("sleep.permission.body", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)

                Button {
                    onRequest()
                } label: {
                    Text("sleep.permission.cta", bundle: .module)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct SleepPeriodPicker: View {
    @Binding var selectedPeriod: SleepCorrelationPeriod

    var body: some View {
        Picker(
            selection: $selectedPeriod
        ) {
            ForEach(SleepCorrelationPeriod.allCases) { period in
                Text(LocalizedStringKey(period.titleKey), bundle: .module)
                    .tag(period)
            }
        } label: {
            Text("sleep.period.label", bundle: .module)
        }
        .pickerStyle(.segmented)
    }
}

struct SleepScatterPlotCard: View {
    let points: [SleepSpendingDataPoint]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("sleep.scatter.title", bundle: .module)
                .font(.kaso.titleMedium)

            Canvas { context, size in
                drawPoints(context: context, size: size)
            }
            .frame(height: Layout.chartHeight)
            .accessibilityLabel(Text("sleep.scatter.accessibility", bundle: .module))
            .animation(reduceMotion ? nil : .spring(response: 0.6), value: points)
        }
    }

    private func drawPoints(context: GraphicsContext, size: CGSize) {
        guard points.isEmpty == false else {
            return
        }

        let maxSpending = points.map(\.totalSpending).max() ?? 1
        let minSleep = 4.0
        let maxSleep = 10.0

        for point in points {
            let xRatio = (point.sleepHours - minSleep) / (maxSleep - minSleep)
            let yRatio = NSDecimalNumber(decimal: point.totalSpending / maxSpending).doubleValue
            let x = max(0, min(size.width, size.width * xRatio))
            let y = max(0, min(size.height, size.height - size.height * yRatio))
            let radius = CGFloat(4 + min(point.transactionCount, 6))
            let rect = CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(color(for: point.sleepQuality).opacity(Layout.dotOpacity))
            )
        }
    }

    private func color(for quality: SleepQuality) -> Color {
        switch quality {
        case .poor:
            return Color.kaso.destructive
        case .fair:
            return Color.kaso.warning
        case .good:
            return Color.kaso.positive
        }
    }
}

struct SleepInsightCard: View {
    let insight: SleepCorrelationInsight
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("sleep.insight.title", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Text(insight.correlationCoefficient.formatted(.number.precision(.fractionLength(2))))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(color)
            }

            Text(LocalizedStringKey("sleep.significance.\(insight.significance.rawValue)"), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(color)

            ForEach(visibleInsights, id: \.self) { text in
                Text(text)
                    .font(.kaso.body)
            }

            Button {
                onToggle()
            } label: {
                Text(
                    LocalizedStringKey(isExpanded ? "sleep.insight.collapse" : "sleep.insight.expand"),
                    bundle: .module
                )
            }

            Text(insight.disclaimer)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
    }

    private var visibleInsights: [String] {
        if isExpanded {
            return insight.insights
        }
        return Array(insight.insights.prefix(1))
    }

    private var color: Color {
        switch insight.significance {
        case .insufficient, .weak:
            Color.kaso.warning
        case .moderate:
            Color.kaso.warning
        case .strong:
            Color.kaso.positive
        }
    }
}

struct SleepQualityBreakdown: View {
    let points: [SleepSpendingDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("sleep.breakdown.title", bundle: .module)
                .font(.kaso.titleMedium)

            HStack(alignment: .bottom, spacing: Spacing.md) {
                ForEach([SleepQuality.poor, .fair, .good], id: \.self) { quality in
                    VStack(spacing: Spacing.sm) {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(color(for: quality))
                            .frame(height: barHeight(for: quality))
                        Text(LocalizedStringKey(quality.titleKey), bundle: .module)
                            .font(.kaso.caption)
                        Text(average(for: quality).formatted(.currency(code: "VND")))
                            .font(.kaso.caption)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: Layout.breakdownHeight)
        }
    }

    private func average(for quality: SleepQuality) -> Decimal {
        let matching = points.filter { $0.sleepQuality == quality }
        guard matching.isEmpty == false else {
            return 0
        }
        return matching.reduce(Decimal(0)) { $0 + $1.totalSpending } / Decimal(matching.count)
    }

    private func barHeight(for quality: SleepQuality) -> CGFloat {
        let averages = [SleepQuality.poor, .fair, .good].map(average)
        let maximum = averages.max() ?? 0
        guard maximum > 0 else {
            return Layout.minimumBarHeight
        }
        let ratio = NSDecimalNumber(decimal: average(for: quality) / maximum).doubleValue
        return max(Layout.minimumBarHeight, Layout.maxBarHeight * ratio)
    }

    private func color(for quality: SleepQuality) -> Color {
        switch quality {
        case .poor:
            return Color.kaso.destructive
        case .fair:
            return Color.kaso.warning
        case .good:
            return Color.kaso.positive
        }
    }
}

struct SleepInsufficientDataView: View {
    let currentCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("sleep.insufficient.title", bundle: .module)
                .font(.kaso.titleMedium)
            ProgressView(
                value: Double(min(currentCount, SleepCorrelationInsight.minimumDataPoints)),
                total: Double(SleepCorrelationInsight.minimumDataPoints)
            )
            Text(
                String(
                    format: String(localized: "sleep.insufficient.body", bundle: .module),
                    currentCount,
                    SleepCorrelationInsight.minimumDataPoints
                )
            )
            .font(.kaso.body)
            .foregroundStyle(Color.kaso.textSecondary)
        }
    }
}

private enum Layout {
    static let chartHeight: CGFloat = 220
    static let dotOpacity: Double = 0.85
    static let breakdownHeight: CGFloat = 180
    static let maxBarHeight: CGFloat = 110
    static let minimumBarHeight: CGFloat = 8
}
