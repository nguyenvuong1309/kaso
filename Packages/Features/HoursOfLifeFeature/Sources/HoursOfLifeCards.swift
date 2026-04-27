import KasoDesignSystem
import SwiftUI
import TransactionDomain
import WellnessDomain

struct HoursOfLifeRateCard: View {
    let configuration: HoursOfLifeConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("hoursOfLife.rate.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if let perHour = configuration.netIncomePerWorkHour {
                Text(perHour.formatted(.currency(code: "VND")))
                    .font(.kaso.numericLarge)
                    .foregroundStyle(Color.kaso.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)

                Text("hoursOfLife.rate.subtitle", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            HStack(spacing: Spacing.md) {
                HoursOfLifeMetricBlock(
                    titleKey: "hoursOfLife.rate.income",
                    value: configuration.monthlyNetIncome.formatted(.currency(code: "VND"))
                )
                HoursOfLifeMetricBlock(
                    titleKey: "hoursOfLife.rate.workHours",
                    value: HoursOfLifeDurationFormatter.hoursPerMonth(
                        configuration.averageMonthlyWorkHours
                    )
                )
            }
        }
    }
}

struct HoursOfLifeOnboardingCard: View {
    let onConfigureTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label {
                Text("hoursOfLife.onboarding.title", bundle: .module)
                    .font(.kaso.titleMedium)
            } icon: {
                Image(systemName: "clock.badge.questionmark")
                    .foregroundStyle(Color.kaso.accent)
            }

            Text("hoursOfLife.onboarding.body", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            Button {
                onConfigureTapped()
            } label: {
                Label {
                    Text("hoursOfLife.onboarding.configure", bundle: .module)
                } icon: {
                    Image(systemName: "gearshape")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kaso.accent)
        }
    }
}

struct HoursOfLifeCalculatorCard: View {
    @Binding var amountText: String
    let conversion: HoursOfLifeConversion?
    let isConfigured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("hoursOfLife.calculator.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("hoursOfLife.calculator.subtitle", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(Color.kaso.accent)
                TextField(
                    text: $amountText,
                    prompt: Text("hoursOfLife.calculator.amountPrompt", bundle: .module)
                ) {
                    Text("hoursOfLife.calculator.amountField", bundle: .module)
                }
                .kasoDecimalKeyboard()
                .font(.kaso.numericMedium)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.kaso.surfaceSecondary)
            )

            if isConfigured == false {
                Text("hoursOfLife.calculator.notConfigured", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else if let conversion {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(HoursOfLifeDurationFormatter.duration(for: conversion))
                        .font(.kaso.numericLarge)
                        .foregroundStyle(Color.kaso.warning)
                        .lineLimit(1)
                        .minimumScaleFactor(Layout.amountMinimumScaleFactor)
                    Text("hoursOfLife.calculator.workTime", bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }
        }
    }
}

struct HoursOfLifeRecentCard: View {
    let rows: [HoursOfLifeRecentRow]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("hoursOfLife.recent.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if rows.isEmpty {
                Text("hoursOfLife.recent.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(rows) { row in
                    HoursOfLifeRecentRowView(row: row)
                    if row.id != rows.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct HoursOfLifeMetricBlock: View {
    let titleKey: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HoursOfLifeRecentRowView: View {
    let row: HoursOfLifeRecentRow

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: row.transaction.category.symbolName)
                .foregroundStyle(Color.kaso.category(named: row.transaction.category.colorName))
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(row.transaction.amount.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)

                Text(row.transaction.occurredAt.formatted(.dateTime.day().month().year()))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(HoursOfLifeDurationFormatter.duration(for: row.conversion))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.warning)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)
                Text("hoursOfLife.recent.workLabel", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
}
