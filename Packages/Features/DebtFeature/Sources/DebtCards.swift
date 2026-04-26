import SwiftUI
import ComposableArchitecture
import DebtDomain
import KasoDesignSystem

struct DebtSummaryCard: View {
    let summary: DebtSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("debt.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(summary.totalPrincipalRemaining.formatted(.currency(code: "VND")))
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.destructive)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            HStack(spacing: Spacing.sm) {
                DebtMetric(
                    titleKey: "debt.summary.monthlyPayment",
                    amount: summary.totalMonthlyPayment,
                    symbolName: "calendar.badge.clock",
                    color: Color.kaso.accent
                )
                DebtMetric(
                    titleKey: "debt.summary.projectedInterest",
                    amount: summary.totalProjectedInterest,
                    symbolName: "percent",
                    color: Color.kaso.warning
                )
            }
        }
    }
}

struct SelectedDebtCard: View {
    let debts: [Debt]
    let selectedDebtID: UUID?
    let schedule: AmortizationSchedule?
    let referenceDate: Date
    let onDebtSelected: (UUID?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("debt.selected.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if debts.isEmpty {
                Text("debt.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                Picker(
                    selection: Binding(
                        get: { selectedDebtID },
                        set: { onDebtSelected($0) }
                    )
                ) {
                    ForEach(debts) { debt in
                        Text(debt.name)
                            .tag(Optional(debt.id))
                    }
                } label: {
                    Text("debt.selected.picker", bundle: .module)
                }
                .pickerStyle(.menu)

                if let schedule {
                    DebtScheduleSummary(schedule: schedule, referenceDate: referenceDate)
                    DebtUpcomingPayments(entries: Array(schedule.entriesAfter(referenceDate).prefix(Layout.entryLimit)))
                }
            }
        }
    }
}

struct ExtraPaymentCard: View {
    @Bindable var store: StoreOf<DebtFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("debt.extra.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("debt.extra.description", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            TextField(
                text: $store.extraMonthlyPaymentText.sending(\.extraMonthlyPaymentTextChanged)
            ) {
                Text("debt.extra.monthly", bundle: .module)
            }
            .textFieldStyle(.roundedBorder)

            TextField(
                text: $store.oneTimeExtraPaymentText.sending(\.oneTimeExtraPaymentTextChanged)
            ) {
                Text("debt.extra.oneTime", bundle: .module)
            }
            .textFieldStyle(.roundedBorder)

            if let result = store.extraPaymentResult {
                HStack(spacing: Spacing.sm) {
                    DebtPlainMetric(
                        titleKey: "debt.extra.monthsSaved",
                        value: result.monthsSaved.formatted()
                    )
                    DebtPlainMetric(
                        titleKey: "debt.extra.interestSaved",
                        value: result.interestSaved.formatted(.currency(code: "VND"))
                    )
                }
            }
        }
    }
}

private struct DebtMetric: View {
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

private struct DebtPlainMetric: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(value)
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.positive)
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.positive.opacity(Layout.positiveBackgroundOpacity))
        )
    }
}

private struct DebtScheduleSummary: View {
    let schedule: AmortizationSchedule
    let referenceDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ProgressView(value: schedule.progressFraction(asOf: referenceDate))
                .tint(Color.kaso.positive)
            HStack {
                Text("debt.schedule.monthly", bundle: .module)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(schedule.monthlyPayment.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
            }
            HStack {
                Text("debt.schedule.totalInterest", bundle: .module)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(schedule.totalInterest.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
            }
        }
        .font(.kaso.caption)
    }
}

private struct DebtUpcomingPayments: View {
    let entries: [AmortizationEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("debt.schedule.upcoming", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(entries) { entry in
                HStack {
                    Text(entry.dueDate.formatted(.dateTime.day().month().year()))
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Spacer()
                    Text(entry.payment.formatted(.currency(code: "VND")))
                        .font(.kaso.numericMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                }
            }
        }
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let entryLimit = 5
    static let positiveBackgroundOpacity: Double = 0.12
}
