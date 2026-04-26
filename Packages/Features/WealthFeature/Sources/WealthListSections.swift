import SwiftUI
import KasoDesignSystem
import WealthDomain

struct WealthAssetSection: View {
    let assets: [Asset]
    let onAddTapped: () -> Void
    let onEditTapped: (Asset) -> Void
    let onDeleteTapped: (Asset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            WealthSectionHeader(
                titleKey: "wealth.asset.title",
                addKey: "wealth.asset.add",
                onAddTapped: onAddTapped
            )

            if assets.isEmpty {
                WealthEmptyText(messageKey: "wealth.asset.empty")
            } else {
                ForEach(assets) { asset in
                    WealthItemRow(
                        name: asset.name,
                        typeKey: asset.type.nameKey,
                        amount: asset.currentValue,
                        symbolName: asset.type.symbolName,
                        colorName: asset.type.colorName,
                        amountColor: Color.kaso.positive,
                        onEditTapped: {
                            onEditTapped(asset)
                        },
                        onDeleteTapped: {
                            onDeleteTapped(asset)
                        }
                    )
                }
            }
        }
    }
}

struct WealthLiabilitySection: View {
    let liabilities: [Liability]
    let onAddTapped: () -> Void
    let onEditTapped: (Liability) -> Void
    let onDeleteTapped: (Liability) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            WealthSectionHeader(
                titleKey: "wealth.liability.title",
                addKey: "wealth.liability.add",
                onAddTapped: onAddTapped
            )

            if liabilities.isEmpty {
                WealthEmptyText(messageKey: "wealth.liability.empty")
            } else {
                ForEach(liabilities) { liability in
                    WealthItemRow(
                        name: liability.name,
                        typeKey: liability.type.nameKey,
                        amount: liability.principalRemaining,
                        symbolName: liability.type.symbolName,
                        colorName: liability.type.colorName,
                        amountColor: Color.kaso.destructive,
                        onEditTapped: {
                            onEditTapped(liability)
                        },
                        onDeleteTapped: {
                            onDeleteTapped(liability)
                        }
                    )
                }
            }
        }
    }
}

private struct WealthSectionHeader: View {
    let titleKey: String
    let addKey: String
    let onAddTapped: () -> Void

    var body: some View {
        HStack {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Spacer(minLength: Spacing.md)

            Button {
                onAddTapped()
            } label: {
                Label {
                    Text(LocalizedStringKey(addKey), bundle: .module)
                } icon: {
                    Image(systemName: "plus")
                }
            }
            .font(.kaso.caption)
        }
    }
}

private struct WealthEmptyText: View {
    let messageKey: String

    var body: some View {
        Text(LocalizedStringKey(messageKey), bundle: .module)
            .font(.kaso.body)
            .foregroundStyle(Color.kaso.textSecondary)
    }
}

private struct WealthItemRow: View {
    let name: String
    let typeKey: String
    let amount: Decimal
    let symbolName: String
    let colorName: String
    let amountColor: Color
    let onEditTapped: () -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbolName)
                .foregroundStyle(Color.kaso.category(named: colorName))
                .frame(width: Layout.iconSize, height: Layout.iconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(name)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(LocalizedStringKey(typeKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            Text(amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)

            Menu {
                Button {
                    onEditTapped()
                } label: {
                    Text("wealth.row.edit", bundle: .module)
                }
                Button(role: .destructive) {
                    onDeleteTapped()
                } label: {
                    Text("wealth.row.delete", bundle: .module)
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
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.72
    static let iconSize: CGFloat = 28
}
