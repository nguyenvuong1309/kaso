import ComposableArchitecture
import HuiTrackerDomain
import KasoDesignSystem
import SwiftUI

public struct HuiTrackerView: View {
    @Bindable var store: StoreOf<HuiTrackerFeature>

    public init(store: StoreOf<HuiTrackerFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.groups.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle(Text("hui.title", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isEditorPresented },
            set: { if !$0 { store.send(.editorDismissed) } }
        )) {
            HuiGroupEditorSheet(store: store)
        }
        .task { await store.send(.task).finish() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HuiOverallSummaryCard(summary: store.overallSummary)
                    .padding(.horizontal, Spacing.md)

                Text("hui.disclaimer", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .padding(.horizontal, Spacing.md)

                if let group = store.selectedGroup {
                    groupDetailSection(group)
                } else {
                    groupListSection
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var groupListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("hui.section.groups", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .padding(.horizontal, Spacing.md)

            ForEach(store.groupSummaries) { summary in
                Button {
                    store.send(.groupSelected(summary.id))
                } label: {
                    HuiGroupSummaryRow(summary: summary)
                        .padding(.horizontal, Spacing.md)
                }
                .tint(.primary)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.send(.deleteButtonTapped(summary.id))
                    } label: {
                        Image(systemName: "trash")
                    }

                    if let group = store.groups[id: summary.id] {
                        Button {
                            store.send(.editButtonTapped(group))
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .tint(.blue)
                    }
                }

                Divider()
                    .padding(.leading, Spacing.md)
            }
        }
    }

    private func groupDetailSection(_ group: HuiGroup) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                store.send(.groupDeselected)
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.kaso.caption)
                    Text("hui.back", bundle: .module)
                }
                .foregroundStyle(Color.kaso.accent)
            }
            .padding(.horizontal, Spacing.md)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text("hui.detail.organizer \(group.organizerName)", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Text(group.contributionAmount, format: .currency(code: "VND"))
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, Spacing.md)

            ForEach(group.cycles) { cycle in
                HuiCycleRow(
                    cycle: cycle,
                    contributionAmount: group.contributionAmount,
                    onTogglePaid: {
                        store.send(.cyclePaidToggled(groupID: group.id, cycleID: cycle.id))
                    },
                    onToggleReceived: {
                        store.send(.cycleReceivedToggled(groupID: group.id, cycleID: cycle.id))
                    }
                )
                .padding(.horizontal, Spacing.md)

                Divider()
                    .padding(.leading, Spacing.md)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("hui.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("hui.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                store.send(.addButtonTapped)
            } label: {
                Text("hui.add.button", bundle: .module)
                    .font(Font.kaso.body)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kaso.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HuiOverallSummaryCard: View {
    let summary: HuiOverallSummary

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("hui.summary.title", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text("hui.summary.activeGroups \(String(summary.activeGroupCount))", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("hui.summary.contributed", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(summary.totalContributed, format: .currency(code: "VND"))
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("hui.summary.received", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(summary.totalReceived, format: .currency(code: "VND"))
                        .font(Font.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.positive)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }
}

private struct HuiGroupSummaryRow: View {
    let summary: HuiGroupSummary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.kaso.surfaceSecondary)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.name)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                Text("hui.row.progress \(String(summary.paidCycleCount)) \(String(summary.totalCycleCount))", bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(summary.netPosition, format: .currency(code: "VND"))
                    .font(Font.kaso.caption)
                    .foregroundStyle(
                        summary.netPosition >= 0 ? Color.kaso.positive : Color.kaso.textPrimary
                    )

                Image(systemName: "chevron.right")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct HuiCycleRow: View {
    let cycle: HuiCycle
    let contributionAmount: Decimal
    let onTogglePaid: () -> Void
    let onToggleReceived: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("hui.cycle.index \(String(cycle.index))", bundle: .module)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(cycle.dueDate, style: .date)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.7))
                if cycle.isReceived, let amount = cycle.receivedAmount {
                    Text("hui.cycle.received \(amount.formatted(.currency(code: "VND")))", bundle: .module)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.positive)
                }
            }

            Spacer()

            Button(action: onToggleReceived) {
                Image(systemName: cycle.isReceived ? "hands.sparkles.fill" : "hands.sparkles")
                    .foregroundStyle(cycle.isReceived ? Color.kaso.positive : Color.kaso.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("hui.cycle.toggleReceived", bundle: .module))

            Button(action: onTogglePaid) {
                Image(systemName: cycle.isPaid ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(cycle.isPaid ? Color.kaso.accent : Color.kaso.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("hui.cycle.togglePaid", bundle: .module))
        }
        .padding(.vertical, Spacing.xs)
    }
}
