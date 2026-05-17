import GuiltFreeBudgetDomain
import KasoDesignSystem
import SwiftUI

struct GuiltFreeHeadlineCard: View {
    let budget: GuiltFreeBudget
    let dailyAllowance: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("guiltFree.headline.freeMoney", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(GuiltFreeFormatters.currency(max(budget.freeMoney, 0)))
                .font(.kaso.titleLarge)
                .foregroundStyle(headlineColor)

            Text(LocalizedStringKey(healthMessageKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(healthColor)

            Divider().padding(.vertical, Spacing.xs)

            HStack(alignment: .firstTextBaseline) {
                Text("guiltFree.headline.dailyAllowance", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(GuiltFreeFormatters.currency(dailyAllowance))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(budget.freeMoney > 0 ? Color.kaso.positive : Color.kaso.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headlineColor: Color {
        switch budget.health {
        case .healthy:
            Color.kaso.positive
        case .tight:
            Color.kaso.warning
        case .overspending:
            Color.kaso.destructive
        case .incomeMissing:
            Color.kaso.textSecondary
        }
    }

    private var healthColor: Color {
        switch budget.health {
        case .healthy:
            Color.kaso.positive
        case .tight:
            Color.kaso.warning
        case .overspending:
            Color.kaso.destructive
        case .incomeMissing:
            Color.kaso.textSecondary
        }
    }

    private var healthMessageKey: String {
        switch budget.health {
        case .healthy:
            "guiltFree.health.healthy"
        case .tight:
            "guiltFree.health.tight"
        case .overspending:
            "guiltFree.health.overspending"
        case .incomeMissing:
            "guiltFree.health.incomeMissing"
        }
    }
}

struct GuiltFreeBreakdownCard: View {
    let budget: GuiltFreeBudget

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("guiltFree.breakdown.headline", bundle: .module)
                .font(.kaso.titleMedium)

            ProgressBar(segments: segments)
                .frame(height: 14)
                .accessibilityLabel(Text("guiltFree.breakdown.accessibility", bundle: .module))

            VStack(spacing: Spacing.xs) {
                breakdownRow(
                    color: Color.kaso.warning,
                    labelKey: "guiltFree.breakdown.fixedCosts",
                    amount: budget.totalFixedCosts
                )
                breakdownRow(
                    color: Color.kaso.accent,
                    labelKey: "guiltFree.breakdown.savings",
                    amount: budget.totalSavings + budget.totalEmergency
                )
                breakdownRow(
                    color: Color.kaso.positive,
                    labelKey: "guiltFree.breakdown.freeMoney",
                    amount: max(budget.freeMoney, 0)
                )
                if budget.freeMoney < 0 {
                    breakdownRow(
                        color: Color.kaso.destructive,
                        labelKey: "guiltFree.breakdown.shortfall",
                        amount: -budget.freeMoney
                    )
                }
            }
        }
    }

    private var segments: [ProgressBar.Segment] {
        var result: [ProgressBar.Segment] = []
        if budget.fixedCostsRatio > 0 {
            result.append(.init(ratio: budget.fixedCostsRatio, color: Color.kaso.warning))
        }
        if budget.savingsRatio > 0 {
            result.append(.init(ratio: budget.savingsRatio, color: Color.kaso.accent))
        }
        let remaining = max(1.0 - budget.fixedCostsRatio - budget.savingsRatio, 0)
        if remaining > 0 {
            let color = budget.freeMoney >= 0 ? Color.kaso.positive : Color.kaso.destructive
            result.append(.init(ratio: remaining, color: color))
        }
        return result
    }

    @ViewBuilder
    private func breakdownRow(color: Color, labelKey: String, amount: Decimal) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.kaso.caption)
            Spacer()
            Text(GuiltFreeFormatters.currency(amount))
                .font(.kaso.numericMedium)
        }
    }
}

struct GuiltFreeIncomeCard: View {
    let configuration: GuiltFreeBudgetConfiguration
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("guiltFree.income.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Text("guiltFree.income.edit", bundle: .module)
                }
                .font(.kaso.caption)
            }
            row(
                labelKey: "guiltFree.income.monthly",
                amount: configuration.monthlyIncome
            )
            row(
                labelKey: "guiltFree.income.savings",
                amount: configuration.monthlySavingsTarget
            )
            row(
                labelKey: "guiltFree.income.emergency",
                amount: configuration.emergencyFundMonthlyContribution
            )
        }
    }

    @ViewBuilder
    private func row(labelKey: String, amount: Decimal) -> some View {
        HStack {
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.kaso.body)
            Spacer()
            Text(GuiltFreeFormatters.currency(amount))
                .font(.kaso.numericMedium)
                .foregroundStyle(amount > 0 ? Color.kaso.textPrimary : Color.kaso.textSecondary)
        }
    }
}

struct GuiltFreeFixedCostsCard: View {
    let fixedCosts: [GuiltFreeFixedCost]
    let onAdd: () -> Void
    let onEdit: (GuiltFreeFixedCost) -> Void
    let onDelete: (GuiltFreeFixedCost) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("guiltFree.fixedCosts.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Label {
                        Text("guiltFree.fixedCosts.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.kaso.caption)
            }

            if fixedCosts.isEmpty {
                Text("guiltFree.fixedCosts.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(fixedCosts) { cost in
                        GuiltFreeFixedCostRow(
                            cost: cost,
                            onEdit: { onEdit(cost) },
                            onDelete: { onDelete(cost) }
                        )
                    }
                }
            }
        }
    }
}

private struct GuiltFreeFixedCostRow: View {
    let cost: GuiltFreeFixedCost
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: cost.kind.symbolName)
                .foregroundStyle(Color.kaso.warning)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(cost.name)
                    .font(.kaso.body)
                Text(LocalizedStringKey(cost.kind.nameKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
            Spacer()
            Text(GuiltFreeFormatters.currency(cost.amount))
                .font(.kaso.numericMedium)
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label {
                        Text("guiltFree.fixedCosts.editAction", bundle: .module)
                    } icon: {
                        Image(systemName: "pencil")
                    }
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label {
                        Text("guiltFree.fixedCosts.deleteAction", bundle: .module)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(Text("guiltFree.fixedCosts.menu", bundle: .module))
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct ProgressBar: View {
    struct Segment: Identifiable {
        let id = UUID()
        let ratio: Double
        let color: Color
    }

    let segments: [Segment]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: geometry.size.width * CGFloat(min(max(segment.ratio, 0), 1)))
                }
            }
            .clipShape(Capsule())
            .background(
                Capsule().fill(Color.kaso.surfaceSecondary.opacity(0.6))
            )
        }
    }
}
