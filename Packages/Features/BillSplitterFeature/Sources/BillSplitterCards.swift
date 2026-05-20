import BillSplitterDomain
import KasoDesignSystem
import SwiftUI

struct BillSplitterHeaderCard: View {
    @Binding var title: String
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("billSplitter.header.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Button(action: onReset) {
                    Text("billSplitter.action.reset", bundle: .module)
                }
                .font(.kaso.caption)
            }
            Text("billSplitter.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
            TextField(
                "billSplitter.title.placeholder",
                text: $title
            )
            .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BillSplitterParticipantsCard: View {
    let participants: [BillParticipant]
    let payerID: UUID?
    @Binding var newName: String
    let onAdd: () -> Void
    let onRemove: (UUID) -> Void
    let onSelectPayer: (UUID?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("billSplitter.participants.title", bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)

            HStack {
                TextField(
                    "billSplitter.participants.placeholder",
                    text: $newName
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit(onAdd)
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("billSplitter.participants.add", bundle: .module))
            }

            if participants.isEmpty {
                Text("billSplitter.participants.empty", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(participants) { participant in
                    HStack {
                        Button {
                            onSelectPayer(participant.id)
                        } label: {
                            Image(
                                systemName: payerID == participant.id
                                    ? "creditcard.fill"
                                    : "creditcard"
                            )
                            .foregroundStyle(
                                payerID == participant.id
                                    ? Color.kaso.accent
                                    : Color.kaso.textSecondary
                            )
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text("billSplitter.participants.payer", bundle: .module))

                        Text(participant.name)
                            .font(.kaso.body)
                            .foregroundStyle(Color.kaso.textPrimary)
                        Spacer()
                        Button(role: .destructive) {
                            onRemove(participant.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BillSplitterItemsCard: View {
    let items: [BillItem]
    let participants: [BillParticipant]
    @Binding var newLabel: String
    @Binding var newAmount: String
    let onAdd: () -> Void
    let onRemove: (UUID) -> Void
    let onToggleAssignment: (UUID, UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("billSplitter.items.title", bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)

            HStack {
                TextField(
                    "billSplitter.items.labelPlaceholder",
                    text: $newLabel
                )
                .textFieldStyle(.roundedBorder)
                TextField(
                    "billSplitter.items.amountPlaceholder",
                    text: $newAmount
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 120)
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("billSplitter.items.add", bundle: .module))
            }

            if items.isEmpty {
                Text("billSplitter.items.empty", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(items) { item in
                    BillSplitterItemRow(
                        item: item,
                        participants: participants,
                        onRemove: { onRemove(item.id) },
                        onToggleAssignment: { participantID in
                            onToggleAssignment(item.id, participantID)
                        }
                    )
                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BillSplitterItemRow: View {
    let item: BillItem
    let participants: [BillParticipant]
    let onRemove: () -> Void
    let onToggleAssignment: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(item.label)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Text(item.amount, format: .currency(code: "VND"))
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            if participants.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(participants) { participant in
                            let assigned = item.assignedTo.contains(participant.id)
                                || item.assignedTo.isEmpty
                            Button {
                                onToggleAssignment(participant.id)
                            } label: {
                                Text(participant.name)
                                    .font(.kaso.caption)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule().fill(
                                            assigned
                                                ? Color.kaso.accent.opacity(0.18)
                                                : Color.kaso.surfaceSecondary
                                        )
                                    )
                                    .foregroundStyle(
                                        assigned
                                            ? Color.kaso.accent
                                            : Color.kaso.textSecondary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Text("billSplitter.items.assignmentHint", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }
}

struct BillSplitterTipCard: View {
    let tipMode: BillTipMode
    let onChange: (BillTipMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("billSplitter.tip.title", bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)
            HStack {
                ForEach(BillTipMode.allCases, id: \.self) { mode in
                    Button {
                        onChange(mode)
                    } label: {
                        Text(LocalizedStringKey(label(for: mode)), bundle: .module)
                            .font(.kaso.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    tipMode == mode
                                        ? Color.kaso.accent.opacity(0.2)
                                        : Color.kaso.surfaceSecondary
                                )
                            )
                            .foregroundStyle(
                                tipMode == mode
                                    ? Color.kaso.accent
                                    : Color.kaso.textSecondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func label(for mode: BillTipMode) -> String {
        switch mode {
        case .none: "billSplitter.tip.none"
        case .percent10: "billSplitter.tip.10"
        case .percent15: "billSplitter.tip.15"
        case .percent20: "billSplitter.tip.20"
        }
    }
}

struct BillSplitterSummaryCard: View {
    let result: BillSplitResult
    let shareText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("billSplitter.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            HStack {
                Text("billSplitter.summary.subtotal", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(result.subtotal, format: .currency(code: "VND"))
                    .font(.kaso.body)
            }
            HStack {
                Text("billSplitter.summary.tip", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(result.tip, format: .currency(code: "VND"))
                    .font(.kaso.body)
            }
            HStack {
                Text("billSplitter.summary.total", bundle: .module)
                    .font(.kaso.body.weight(.semibold))
                Spacer()
                Text(result.total, format: .currency(code: "VND"))
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.accent)
            }

            Divider()

            ForEach(result.shares) { share in
                HStack {
                    Image(
                        systemName: share.isPayer
                            ? "creditcard.fill"
                            : "person.fill"
                    )
                    .foregroundStyle(
                        share.isPayer ? Color.kaso.accent : Color.kaso.textSecondary
                    )
                    Text(share.name)
                        .font(.kaso.body)
                    Spacer()
                    Text(share.owes, format: .currency(code: "VND"))
                        .font(.kaso.body)
                }
            }

            if result.settlements.isEmpty == false {
                Divider()
                Text("billSplitter.summary.settlements", bundle: .module)
                    .font(.kaso.body.weight(.semibold))
                ForEach(result.settlements) { settlement in
                    HStack {
                        Text(
                            "\(settlement.fromName) → \(settlement.toName)"
                        )
                        .font(.kaso.caption)
                        Spacer()
                        Text(settlement.amount, format: .currency(code: "VND"))
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.accent)
                    }
                }
                ShareLink(item: shareText) {
                    Label {
                        Text("billSplitter.summary.share", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
