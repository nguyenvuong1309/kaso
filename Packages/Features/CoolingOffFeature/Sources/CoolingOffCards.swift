import CoolingOffDomain
import KasoDesignSystem
import SwiftUI

struct CoolingOffSummaryCard: View {
    let summary: PurchasePlanSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("coolingOff.summary.headline", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(CoolingOffFormatters.currency(summary.totalAvoidedAmount))
                .font(.kaso.titleLarge)
                .foregroundStyle(Color.kaso.positive)

            Text("coolingOff.summary.avoidedSubtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            Divider().padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.md) {
                metric(
                    labelKey: "coolingOff.summary.waiting",
                    value: String(summary.waiting.count + summary.ready.count)
                )
                metric(
                    labelKey: "coolingOff.summary.waitingAmount",
                    value: CoolingOffFormatters.currency(summary.totalWaitingAmount)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CoolingOffPlanSectionCard: View {
    let titleKey: String
    let subtitleKey: String?
    let plans: [PurchasePlan]
    let referenceDate: Date
    let showActions: Bool
    let onApprove: (PurchasePlan) -> Void
    let onCancel: (PurchasePlan) -> Void
    let onEdit: (PurchasePlan) -> Void
    let onDelete: (PurchasePlan) -> Void
    var emptyMessageKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(titleKey), bundle: .module)
                    .font(.kaso.titleMedium)
                if let subtitleKey {
                    Text(LocalizedStringKey(subtitleKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            if plans.isEmpty {
                if let emptyMessageKey {
                    Text(LocalizedStringKey(emptyMessageKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(plans) { plan in
                        CoolingOffPlanRow(
                            plan: plan,
                            referenceDate: referenceDate,
                            showActions: showActions,
                            onApprove: { onApprove(plan) },
                            onCancel: { onCancel(plan) },
                            onEdit: { onEdit(plan) },
                            onDelete: { onDelete(plan) }
                        )
                    }
                }
            }
        }
    }
}

private struct CoolingOffPlanRow: View {
    let plan: PurchasePlan
    let referenceDate: Date
    let showActions: Bool
    let onApprove: () -> Void
    let onCancel: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: plan.category.symbolName)
                    .foregroundStyle(statusColor)
                    .imageScale(.large)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.title)
                        .font(.kaso.body)
                    Text(LocalizedStringKey(plan.category.nameKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    if let note = plan.note {
                        Text(note)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(CoolingOffFormatters.currency(plan.amount))
                        .font(.kaso.numericMedium)
                    statusBadge
                }
            }

            timeLine

            HStack(spacing: Spacing.sm) {
                if showActions && plan.status == .waiting {
                    Button {
                        onApprove()
                    } label: {
                        Label {
                            Text("coolingOff.action.approve", bundle: .module)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.kaso.positive)
                    .controlSize(.small)
                }
                if plan.status == .waiting {
                    Button {
                        onCancel()
                    } label: {
                        Label {
                            Text("coolingOff.action.cancel", bundle: .module)
                        } icon: {
                            Image(systemName: "xmark.circle")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Spacer()
                if plan.status == .waiting {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("coolingOff.action.edit", bundle: .module))
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("coolingOff.action.delete", bundle: .module))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    @ViewBuilder
    private var timeLine: some View {
        if plan.status == .waiting {
            let remaining = plan.remainingSeconds(asOf: referenceDate)
            if remaining > 0 {
                ProgressView(
                    value: progress,
                    label: {
                        Label {
                            Text(
                                String(
                                    format: NSLocalizedString(
                                        "coolingOff.row.remaining",
                                        bundle: .module,
                                        comment: ""
                                    ),
                                    CoolingOffFormatters.duration(remaining)
                                )
                            )
                        } icon: {
                            Image(systemName: "hourglass")
                        }
                    }
                )
                .tint(Color.kaso.warning)
                .font(.kaso.caption)
            } else {
                Label {
                    Text("coolingOff.row.ready", bundle: .module)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.positive)
            }
        } else if let decisionAt = plan.decisionAt {
            Label {
                Text(
                    String(
                        format: NSLocalizedString(
                            "coolingOff.row.decidedAt",
                            bundle: .module,
                            comment: ""
                        ),
                        decisionAt.formatted(date: .abbreviated, time: .shortened)
                    )
                )
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.kaso.caption)
            .foregroundStyle(Color.kaso.textSecondary)
        }
    }

    private var progress: Double {
        let total = plan.coolingPeriod.seconds
        guard total > 0 else {
            return 1
        }
        let elapsed = total - plan.remainingSeconds(asOf: referenceDate)
        return min(max(elapsed / total, 0), 1)
    }

    private var statusBadge: some View {
        Text(LocalizedStringKey(statusLabelKey), bundle: .module)
            .font(.kaso.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule().fill(statusColor.opacity(0.16))
            )
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch plan.status {
        case .waiting:
            plan.isReady(asOf: referenceDate) ? Color.kaso.positive : Color.kaso.warning
        case .approved:
            Color.kaso.destructive
        case .cancelled, .expired:
            Color.kaso.positive
        }
    }

    private var statusLabelKey: String {
        switch plan.status {
        case .waiting:
            plan.isReady(asOf: referenceDate) ? "coolingOff.status.ready" : "coolingOff.status.waiting"
        case .approved:
            "coolingOff.status.approved"
        case .cancelled:
            "coolingOff.status.cancelled"
        case .expired:
            "coolingOff.status.expired"
        }
    }
}
