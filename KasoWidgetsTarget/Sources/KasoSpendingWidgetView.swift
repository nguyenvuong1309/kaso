import KasoWidgetShared
import SwiftUI
import WidgetKit

struct KasoSpendingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KasoSpendingEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .systemMedium:
            medium
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("widget.spending.todayLabel", bundle: .main)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formattedAmount(entry.snapshot.totalSpentToday))
                .font(.title2)
                .fontWeight(.semibold)
            Spacer(minLength: 0)
            budgetBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("widget.spending.todayLabel", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedAmount(entry.snapshot.totalSpentToday))
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(transactionsLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("widget.spending.budgetRemainingLabel", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedAmount(entry.snapshot.budgetRemaining))
                    .font(.title3)
                    .fontWeight(.medium)
                budgetBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("widget.spending.todayLabel", bundle: .main)
                .font(.caption2)
            Text(formattedAmount(entry.snapshot.totalSpentToday))
                .font(.headline)
            Text(transactionsLabel)
                .font(.caption2)
        }
    }

    private var circular: some View {
        Gauge(value: entry.snapshot.budgetUsedFraction) {
            Text("widget.spending.budgetGauge", bundle: .main)
        } currentValueLabel: {
            Text(Int(entry.snapshot.budgetUsedFraction * 100), format: .number)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var inline: some View {
        Text(formattedAmount(entry.snapshot.totalSpentToday))
    }

    private var budgetBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.18))
                Capsule()
                    .fill(.tint)
                    .frame(width: proxy.size.width * entry.snapshot.budgetUsedFraction)
            }
        }
        .frame(height: 6)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: entry.snapshot.currencyCode).presentation(.narrow))
    }

    private var transactionsLabel: LocalizedStringResource {
        LocalizedStringResource(
            "widget.spending.transactionsLabel",
            defaultValue: "\(entry.snapshot.transactionCountToday) giao dịch",
            bundle: .main
        )
    }
}
