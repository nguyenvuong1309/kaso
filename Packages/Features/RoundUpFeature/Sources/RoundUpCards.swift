import ComposableArchitecture
import KasoDesignSystem
import RoundUpDomain
import SwiftUI

struct RoundUpSummaryCard: View {
    let summary: RoundUpJarSummary
    let rule: RoundUpRule

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("roundUp.summary.headline", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(RoundUpFormatters.currency(summary.totalContribution))
                .font(.kaso.titleLarge)
                .foregroundStyle(Color.kaso.positive)
                .accessibilityLabel(Text(RoundUpFormatters.accessibilityCurrency(summary.totalContribution)))

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "roundUp.summary.monthly",
                    value: RoundUpFormatters.currency(summary.monthlyContribution)
                )
                metric(
                    labelKey: "roundUp.summary.monthlyCount",
                    value: String(summary.monthlyEntryCount)
                )
                metric(
                    labelKey: "roundUp.summary.lifetimeCount",
                    value: String(summary.lifetimeEntryCount)
                )
            }

            if rule.isEnabled == false {
                Label {
                    Text("roundUp.summary.disabledHint", bundle: .module)
                } icon: {
                    Image(systemName: "info.circle")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RoundUpRuleCard: View {
    let rule: RoundUpRule
    let isSaving: Bool
    let onToggle: (Bool) -> Void
    let onStepChanged: (RoundUpStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("roundUp.rule.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Toggle(isOn: Binding(get: { rule.isEnabled }, set: onToggle)) {
                Text("roundUp.rule.enabled", bundle: .module)
                    .font(.kaso.body)
            }
            .tint(Color.kaso.positive)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("roundUp.rule.step", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)

                Picker(
                    selection: Binding(get: { rule.step }, set: onStepChanged)
                ) {
                    ForEach(RoundUpStep.allCases) { step in
                        Text(LocalizedStringKey(step.nameKey), bundle: .module)
                            .tag(step)
                    }
                } label: {
                    Text("roundUp.rule.step", bundle: .module)
                }
                .pickerStyle(.segmented)
                .disabled(rule.isEnabled == false)
            }
        }
    }
}

struct RoundUpSimulatorCard: View {
    @Binding var amountText: String
    let contribution: Decimal
    let step: RoundUpStep

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("roundUp.simulator.headline", bundle: .module)
                .font(.kaso.titleMedium)

            Text("roundUp.simulator.description", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            TextField(
                "roundUp.simulator.placeholder",
                text: $amountText
            )
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)

            HStack(alignment: .firstTextBaseline) {
                Text("roundUp.simulator.contribution", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(RoundUpFormatters.currency(contribution))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(contribution > 0 ? Color.kaso.positive : Color.kaso.textSecondary)
            }

            Text(LocalizedStringKey(step.nameKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
    }
}

struct RoundUpHistoryCard: View {
    let entries: [RoundUpEntry]
    let onManualAdd: () -> Void
    let onDelete: (RoundUpEntry) -> Void
    let onClearAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("roundUp.history.headline", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onManualAdd()
                } label: {
                    Label {
                        Text("roundUp.history.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.kaso.caption)
            }

            if entries.isEmpty {
                Text("roundUp.history.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(entries.prefix(8)) { entry in
                        RoundUpEntryRow(entry: entry, onDelete: { onDelete(entry) })
                    }
                }

                if entries.count > 1 {
                    Button(role: .destructive) {
                        onClearAll()
                    } label: {
                        Text("roundUp.history.clearAll", bundle: .module)
                    }
                    .font(.kaso.caption)
                }
            }
        }
    }
}

private struct RoundUpEntryRow: View {
    let entry: RoundUpEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Image(systemName: "leaf.circle.fill")
                .foregroundStyle(Color.kaso.positive)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(RoundUpFormatters.currency(entry.contribution))
                    .font(.kaso.numericMedium)
                Text(
                    String(
                        format: NSLocalizedString(
                            "roundUp.entry.detail",
                            bundle: .module,
                            comment: ""
                        ),
                        RoundUpFormatters.currency(entry.originalAmount),
                        RoundUpFormatters.currency(entry.roundedAmount)
                    )
                )
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                if let note = entry.note {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("roundUp.history.delete", bundle: .module))
        }
        .padding(.vertical, Spacing.xs)
    }
}
