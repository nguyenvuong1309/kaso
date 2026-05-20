import BNPLDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct BNPLView: View {
    @Bindable var store: StoreOf<BNPLFeature>

    public init(store: StoreOf<BNPLFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.obligations.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle(Text("bnpl.title", bundle: .module))
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
            BNPLEditorSheet(store: store)
        }
        .task { await store.send(.task).finish() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                BNPLSummaryCard(summary: store.summary, monthlyIncome: store.monthlyIncome)
                    .padding(.horizontal, Spacing.md)

                obligationsList
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var obligationsList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("bnpl.section.obligations", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .padding(.horizontal, Spacing.md)

            ForEach(store.obligations) { obligation in
                BNPLObligationCard(
                    obligation: obligation,
                    onEdit: { store.send(.editButtonTapped(obligation)) },
                    onDelete: { store.send(.deleteButtonTapped(obligation.id)) },
                    onToggleInstallment: { installmentID in
                        store.send(.installmentToggled(
                            obligationID: obligation.id,
                            installmentID: installmentID
                        ))
                    }
                )
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("bnpl.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("bnpl.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                store.send(.addButtonTapped)
            } label: {
                Text("bnpl.add.button", bundle: .module)
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

private struct BNPLSummaryCard: View {
    let summary: BNPLSummary
    let monthlyIncome: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("bnpl.summary.title", bundle: .module)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer()

                HealthBadge(health: summary.health)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                metricRow(
                    label: Text("bnpl.summary.totalOutstanding", bundle: .module),
                    value: summary.totalOutstanding,
                    color: .kaso.textPrimary
                )
                metricRow(
                    label: Text("bnpl.summary.currentMonth", bundle: .module),
                    value: summary.currentMonthDue,
                    color: .kaso.textPrimary
                )
                metricRow(
                    label: Text("bnpl.summary.nextThreeMonths", bundle: .module),
                    value: summary.nextThreeMonthsDue,
                    color: .kaso.textSecondary
                )

                if summary.overdueAmount > 0 {
                    metricRow(
                        label: Text("bnpl.summary.overdue", bundle: .module),
                        value: summary.overdueAmount,
                        color: .kaso.destructive
                    )
                }
            }

            if monthlyIncome > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("bnpl.summary.exposureRatio", bundle: .module)
                            .font(Font.kaso.caption)
                            .foregroundStyle(Color.kaso.textSecondary)

                        Spacer()

                        Text(String(format: "%.1f%%", summary.exposureRatio * 100))
                            .font(Font.kaso.caption)
                            .foregroundStyle(colorFor(health: summary.health))
                    }

                    ProgressView(value: min(summary.exposureRatio, 0.5), total: 0.5)
                        .tint(colorFor(health: summary.health))
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func metricRow(label: Text, value: Decimal, color: Color) -> some View {
        HStack {
            label
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Spacer()

            Text(value, format: .currency(code: "VND"))
                .font(Font.kaso.body)
                .foregroundStyle(color)
        }
    }

    private func colorFor(health: BNPLHealth) -> Color {
        switch health {
        case .safe: .kaso.positive
        case .caution: .kaso.warning
        case .overexposed, .critical: .kaso.destructive
        }
    }
}

private struct HealthBadge: View {
    let health: BNPLHealth

    var body: some View {
        Text(LocalizedStringKey(health.nameKey), bundle: .module)
            .font(Font.kaso.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch health {
        case .safe: .kaso.positive
        case .caution: .kaso.warning
        case .overexposed, .critical: .kaso.destructive
        }
    }
}

private struct BNPLObligationCard: View {
    let obligation: BNPLObligation
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleInstallment: (UUID) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: obligation.provider.symbolName)
                    .font(Font.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.accent)
                    .frame(width: 40, height: 40)
                    .background(Color.kaso.accent.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(obligation.purchaseName)
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text(obligation.provider.displayName)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(obligation.remainingAmount, format: .currency(code: "VND"))
                        .font(Font.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text("\(obligation.installments.filter(\.isPaid).count)/\(obligation.installments.count)")
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            ProgressView(
                value: NSDecimalNumber(decimal: obligation.paidAmount).doubleValue,
                total: NSDecimalNumber(decimal: obligation.totalAmount).doubleValue
            )
            .tint(Color.kaso.accent)

            HStack {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        Text("bnpl.installments.toggle", bundle: .module)
                    }
                    .font(Font.kaso.caption)
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .tint(.blue)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }

            if isExpanded {
                installmentsList
            }
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var installmentsList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(obligation.installments) { installment in
                HStack {
                    Button {
                        onToggleInstallment(installment.id)
                    } label: {
                        Image(systemName: installment.isPaid ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(installment.isPaid ? Color.kaso.positive : Color.kaso.textSecondary.opacity(0.6))
                    }

                    Text(installment.dueDate, style: .date)
                        .font(Font.kaso.caption)
                        .foregroundStyle(
                            installment.isPaid
                                ? Color.kaso.textSecondary.opacity(0.6)
                                : Color.kaso.textPrimary
                        )

                    Spacer()

                    Text(installment.amount, format: .currency(code: "VND"))
                        .font(Font.kaso.caption)
                        .foregroundStyle(
                            installment.isPaid
                                ? Color.kaso.textSecondary.opacity(0.6)
                                : Color.kaso.textPrimary
                        )
                        .strikethrough(installment.isPaid)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
