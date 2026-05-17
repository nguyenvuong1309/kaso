import KasoDesignSystem
import SwiftUI
import WhatIfDomain

struct WhatIfProjectionCard: View {
    let projection: WhatIfProjection

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("whatIf.projection.headline", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(WhatIfFormatters.currency(projection.endingBalance))
                .font(.kaso.titleLarge)
                .foregroundStyle(projection.endingBalance > 0 ? Color.kaso.positive : Color.kaso.textSecondary)
                .contentTransition(reduceMotion ? .identity : .numericText())
                .animation(.smooth, value: projection.endingBalance)

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "whatIf.projection.monthlySavings",
                    value: WhatIfFormatters.currency(projection.monthlyNetSavings)
                )
                metric(
                    labelKey: "whatIf.projection.savingsRate",
                    value: String(format: "%.0f%%", projection.savingsRate * 100)
                )
            }

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "whatIf.projection.totalSaved",
                    value: WhatIfFormatters.currency(projection.totalSaved)
                )
                metric(
                    labelKey: "whatIf.projection.totalInterest",
                    value: WhatIfFormatters.currency(projection.totalInterestEarned)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metric(labelKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WhatIfBaselineCard: View {
    let baseline: WhatIfBaseline

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("whatIf.baseline.headline", bundle: .module)
                .font(.kaso.titleMedium)

            HStack {
                Text("whatIf.baseline.income", bundle: .module)
                    .font(.kaso.body)
                Spacer()
                Text(WhatIfFormatters.currency(baseline.monthlyIncome))
                    .font(.kaso.numericMedium)
            }
            HStack {
                Text("whatIf.baseline.expenses", bundle: .module)
                    .font(.kaso.body)
                Spacer()
                Text(WhatIfFormatters.currency(baseline.monthlyExpenses))
                    .font(.kaso.numericMedium)
            }

            Text("whatIf.baseline.footnote", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
    }
}

struct WhatIfSlidersCard: View {
    let scenario: WhatIfDomain.WhatIfScenario
    let onIncomeDelta: (Decimal) -> Void
    let onExpenseDelta: (Decimal) -> Void
    let onAdditionalSavings: (Decimal) -> Void
    let onHorizon: (Int) -> Void
    let onReturnRate: (Double) -> Void

    private let incomeDeltaRange: ClosedRange<Double> = -10_000_000 ... 30_000_000
    private let expenseDeltaRange: ClosedRange<Double> = -10_000_000 ... 10_000_000
    private let additionalSavingsRange: ClosedRange<Double> = 0 ... 20_000_000
    private let horizonRange: ClosedRange<Double> = 1 ... 60
    private let returnRateRange: ClosedRange<Double> = 0 ... 0.20

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("whatIf.sliders.headline", bundle: .module)
                .font(.kaso.titleMedium)

            sliderRow(
                labelKey: "whatIf.sliders.incomeDelta",
                value: NSDecimalNumber(decimal: scenario.incomeDelta).doubleValue,
                range: incomeDeltaRange,
                step: 500_000,
                onChange: { onIncomeDelta(Decimal($0)) },
                valueText: WhatIfFormatters.signedCurrency(scenario.incomeDelta)
            )

            sliderRow(
                labelKey: "whatIf.sliders.expenseDelta",
                value: NSDecimalNumber(decimal: scenario.expenseDelta).doubleValue,
                range: expenseDeltaRange,
                step: 500_000,
                onChange: { onExpenseDelta(Decimal($0)) },
                valueText: WhatIfFormatters.signedCurrency(scenario.expenseDelta)
            )

            sliderRow(
                labelKey: "whatIf.sliders.additionalSavings",
                value: NSDecimalNumber(decimal: scenario.additionalSavings).doubleValue,
                range: additionalSavingsRange,
                step: 500_000,
                onChange: { onAdditionalSavings(Decimal($0)) },
                valueText: WhatIfFormatters.currency(scenario.additionalSavings)
            )

            sliderRow(
                labelKey: "whatIf.sliders.horizon",
                value: Double(scenario.horizonMonths),
                range: horizonRange,
                step: 1,
                onChange: { onHorizon(Int($0)) },
                valueText: String(
                    format: NSLocalizedString("whatIf.sliders.horizonValue", bundle: .module, comment: ""),
                    scenario.horizonMonths
                )
            )

            sliderRow(
                labelKey: "whatIf.sliders.returnRate",
                value: scenario.annualInvestmentReturnRate,
                range: returnRateRange,
                step: 0.005,
                onChange: onReturnRate,
                valueText: String(format: "%.1f%%", scenario.annualInvestmentReturnRate * 100)
            )
        }
    }

    @ViewBuilder
    private func sliderRow(
        labelKey: String,
        value: Double,
        range: ClosedRange<Double>,
        step: Double,
        onChange: @escaping (Double) -> Void,
        valueText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(LocalizedStringKey(labelKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(valueText)
                    .font(.kaso.numericMedium)
            }
            Slider(
                value: Binding(get: { value }, set: { onChange($0) }),
                in: range,
                step: step
            )
        }
    }
}

struct WhatIfGoalCard: View {
    @Binding var goalText: String
    let monthsToGoalWithinHorizon: Int?
    let monthsToGoalBeyondHorizon: Int?
    let horizonMonths: Int
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("whatIf.goal.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onReset()
                } label: {
                    Text("whatIf.goal.reset", bundle: .module)
                }
                .font(.kaso.caption)
            }

            TextField(
                "whatIf.goal.placeholder",
                text: $goalText
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)

            if let monthsInside = monthsToGoalWithinHorizon {
                resultLabel(
                    titleKey: "whatIf.goal.reachWithinHorizon",
                    months: monthsInside,
                    accent: Color.kaso.positive
                )
            } else if let monthsBeyond = monthsToGoalBeyondHorizon {
                resultLabel(
                    titleKey: "whatIf.goal.reachBeyondHorizon",
                    months: monthsBeyond,
                    horizon: horizonMonths,
                    accent: Color.kaso.warning
                )
            } else if goalText.isEmpty == false {
                Text("whatIf.goal.unreachable", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.destructive)
            }
        }
    }

    @ViewBuilder
    private func resultLabel(
        titleKey: String,
        months: Int,
        horizon: Int? = nil,
        accent: Color
    ) -> some View {
        let monthsText = String(
            format: NSLocalizedString(
                "whatIf.goal.monthsValue",
                bundle: .module,
                comment: ""
            ),
            months
        )
        let formatted: String = {
            if let horizon {
                return String(
                    format: NSLocalizedString(titleKey, bundle: .module, comment: ""),
                    monthsText,
                    horizon
                )
            }
            return String(
                format: NSLocalizedString(titleKey, bundle: .module, comment: ""),
                monthsText
            )
        }()
        Text(formatted)
            .font(.kaso.body)
            .foregroundStyle(accent)
    }
}
