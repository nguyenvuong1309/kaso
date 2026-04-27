import SwiftUI
import KasoDesignSystem
import PhantomExpenseDomain

struct PhantomExpenseSummaryCard: View {
    let summary: PhantomExpenseMonthlySummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("phantom.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Text(summary.totalAvoided.formatted(.currency(code: "VND")))
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.positive)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            HStack(spacing: Spacing.md) {
                PhantomExpenseMetricBlock(
                    titleKey: "phantom.summary.count",
                    value: "\(summary.count)"
                )
                PhantomExpenseMetricBlock(
                    titleKey: "phantom.summary.average",
                    value: summary.averageAvoided.formatted(.currency(code: "VND"))
                )
            }
        }
    }
}

struct PhantomExpenseCategoryCard: View {
    let summaries: [PhantomExpenseCategorySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("phantom.categoryBreakdown.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            if summaries.isEmpty {
                Text("phantom.categoryBreakdown.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(summaries) { summary in
                    PhantomExpenseCategoryRow(summary: summary)
                }
            }
        }
    }
}

struct PhantomExpenseListCard: View {
    let expenses: [PhantomExpense]
    let onAddTapped: () -> Void
    let onEditTapped: (PhantomExpense) -> Void
    let onDeleteTapped: (PhantomExpense) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("phantom.list.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                Button {
                    onAddTapped()
                } label: {
                    Label {
                        Text("phantom.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
                .font(.kaso.caption)
            }

            if expenses.isEmpty {
                Text("phantom.list.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(expenses) { expense in
                    PhantomExpenseRow(
                        expense: expense,
                        onEditTapped: {
                            onEditTapped(expense)
                        },
                        onDeleteTapped: {
                            onDeleteTapped(expense)
                        }
                    )
                }
            }
        }
    }
}

private struct PhantomExpenseMetricBlock: View {
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

private struct PhantomExpenseCategoryRow: View {
    let summary: PhantomExpenseCategorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Label {
                    Text(LocalizedStringKey(summary.category.nameKey), bundle: .module)
                } icon: {
                    Image(systemName: summary.category.symbolName)
                        .foregroundStyle(Color.kaso.category(named: summary.category.colorName))
                }
                .font(.kaso.body)

                Spacer(minLength: Spacing.md)

                Text(summary.amount.formatted(.currency(code: "VND")))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.kaso.surfacePrimary)
                    Capsule()
                        .fill(Color.kaso.category(named: summary.category.colorName))
                        .frame(width: proxy.size.width * max(0, min(summary.fraction, 1)))
                }
            }
            .frame(height: Layout.progressHeight)
        }
    }
}

private struct PhantomExpenseRow: View {
    let expense: PhantomExpense
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: expense.category.symbolName)
                .foregroundStyle(Color.kaso.category(named: expense.category.colorName))
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(expense.title)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(expense.avoidedAt.formatted(.dateTime.day().month().year()))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            Text(expense.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.positive)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            Menu {
                Button {
                    onEditTapped()
                } label: {
                    Text("phantom.row.edit", bundle: .module)
                }
                Button(role: .destructive) {
                    onDeleteTapped()
                } label: {
                    Text("phantom.row.delete", bundle: .module)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.surfacePrimary)
        )
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
    static let progressHeight: CGFloat = 8
}
