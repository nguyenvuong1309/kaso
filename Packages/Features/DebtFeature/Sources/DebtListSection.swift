import SwiftUI
import DebtDomain
import KasoDesignSystem

struct DebtListSection: View {
    let debts: [Debt]
    let referenceDate: Date
    let onAddTapped: () -> Void
    let onEditTapped: (Debt) -> Void
    let onDeleteTapped: (Debt) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("debt.list.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer(minLength: Spacing.md)
                Button {
                    onAddTapped()
                } label: {
                    Label {
                        Text("debt.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .font(.kaso.caption)
            }

            if debts.isEmpty {
                Text("debt.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(debts) { debt in
                    DebtRow(
                        debt: debt,
                        referenceDate: referenceDate,
                        onEditTapped: {
                            onEditTapped(debt)
                        },
                        onDeleteTapped: {
                            onDeleteTapped(debt)
                        }
                    )
                }
            }
        }
    }
}

private struct DebtRow: View {
    let debt: Debt
    let referenceDate: Date
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: debt.type.symbolName)
                .foregroundStyle(Color.kaso.category(named: debt.type.colorName))
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(debt.name)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(LocalizedStringKey(debt.type.nameKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(remainingBalance.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.destructive)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.amountMinimumScaleFactor)
                Text(monthlyPayment.formatted(.currency(code: "VND")))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Menu {
                Button {
                    onEditTapped()
                } label: {
                    Text("debt.row.edit", bundle: .module)
                }
                Button(role: .destructive) {
                    onDeleteTapped()
                } label: {
                    Text("debt.row.delete", bundle: .module)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfaceSecondary)
        )
    }

    private var schedule: AmortizationSchedule? {
        try? AmortizationCalculator.schedule(for: debt)
    }

    private var remainingBalance: Decimal {
        schedule?.remainingBalance(asOf: referenceDate) ?? debt.principal
    }

    private var monthlyPayment: Decimal {
        schedule?.monthlyPayment ?? 0
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
}
