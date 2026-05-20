import KasoDesignSystem
import SeasonalPlannerDomain
import SwiftUI

struct SeasonalPlannerHeaderCard: View {
    let plan: SeasonalPlan

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("seasonalPlanner.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(subtitleKey, bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleKey: LocalizedStringKey {
        if plan.isSufficient == false {
            return "seasonalPlanner.header.insufficient"
        }
        return plan.spikes.isEmpty
            ? "seasonalPlanner.header.noSpike"
            : "seasonalPlanner.header.hasSpike"
    }
}

struct SeasonalPlannerEmptyStateCard: View {
    let isSufficient: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(titleKey, bundle: .module)
                    .font(.kaso.titleMedium)
            } icon: {
                Image(systemName: isSufficient ? "checkmark.seal" : "hourglass")
            }
            .foregroundStyle(Color.kaso.textPrimary)

            Text(messageKey, bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleKey: LocalizedStringKey {
        isSufficient
            ? "seasonalPlanner.empty.calm.title"
            : "seasonalPlanner.empty.insufficient.title"
    }

    private var messageKey: LocalizedStringKey {
        isSufficient
            ? "seasonalPlanner.empty.calm.message"
            : "seasonalPlanner.empty.insufficient.message"
    }
}

struct SeasonalPlannerSpikeCard: View {
    let spike: SeasonalSpike

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(Color.kaso.accent)
                Text(LocalizedStringKey(spike.nameKey), bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Text(monthLabel)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("seasonalPlanner.spike.historicalLabel", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Text(spike.historicalAverage, format: .currency(code: "VND"))
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("seasonalPlanner.spike.suggestionLabel", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Text(spike.suggestedWeeklySaving, format: .currency(code: "VND"))
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.accent)
                Text(weeksKey, bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let symbols = formatter.monthSymbols ?? []
        let idx = max(0, min(symbols.count - 1, spike.monthIndex - 1))
        return symbols.indices.contains(idx) ? symbols[idx].capitalized : ""
    }

    private var weeksKey: LocalizedStringKey {
        spike.weeksUntil <= 1
            ? "seasonalPlanner.spike.weeks.one"
            : "seasonalPlanner.spike.weeks.many"
    }
}
