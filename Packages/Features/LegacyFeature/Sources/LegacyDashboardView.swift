import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import LegacyDomain

struct LegacyDashboardView: View {
    @Bindable var store: StoreOf<LegacyFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                KasoCard {
                    LegacyVaultSummaryCard(vault: store.vault)
                }

                KasoCard {
                    LegacyAccountSection(
                        accounts: store.vault?.financialAccounts ?? [],
                        onAdd: {
                            store.send(.addAccountButtonTapped)
                        },
                        onEdit: {
                            store.send(.editAccountButtonTapped($0))
                        },
                        onDelete: {
                            store.send(.deleteAccountButtonTapped($0.id))
                        }
                    )
                }

                KasoCard {
                    LegacyInstructionsCard(
                        instructions: $store.instructionsText.sending(\.instructionsChanged),
                        onSave: {
                            store.send(.saveInstructionsButtonTapped)
                        }
                    )
                }
            }
            .padding(Spacing.md)
        }
    }
}

struct LegacyVaultSummaryCard: View {
    let vault: LegacyVault?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("legacy.summary.title", bundle: .module)
                .font(.kaso.titleMedium)

            HStack {
                metric("legacy.summary.accounts", vault?.financialAccounts.count ?? 0)
                Spacer(minLength: Spacing.md)
                metric("legacy.summary.insurance", vault?.insurancePolicies.count ?? 0)
                Spacer(minLength: Spacing.md)
                metric("legacy.summary.contacts", vault?.emergencyContacts.count ?? 0)
            }
        }
    }

    private func metric(_ titleKey: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value.formatted())
                .font(.kaso.numericLarge)
        }
    }
}

struct LegacyAccountSection: View {
    let accounts: [LegacyAccount]
    let onAdd: () -> Void
    let onEdit: (LegacyAccount) -> Void
    let onDelete: (LegacyAccount) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("legacy.accounts.title", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle")
                }
                .accessibilityLabel(Text("legacy.accounts.add", bundle: .module))
            }

            if accounts.isEmpty {
                Text("legacy.accounts.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(accounts) { account in
                    HStack(spacing: Spacing.md) {
                        Image(systemName: symbol(for: account.accountType))
                            .foregroundStyle(Color.kaso.accent)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(account.institutionName)
                                .font(.kaso.body)
                            Text(account.contactInfo)
                                .font(.kaso.caption)
                                .foregroundStyle(Color.kaso.textSecondary)
                        }
                        Spacer()
                        Button {
                            onEdit(account)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete(account)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private func symbol(for type: LegacyAccountType) -> String {
        switch type {
        case .bank:
            return "building.columns"
        case .wallet:
            return "wallet.pass"
        case .crypto:
            return "bitcoinsign.circle"
        case .brokerage:
            return "chart.line.uptrend.xyaxis"
        case .insurance:
            return "shield"
        case .other:
            return "folder"
        }
    }
}

struct LegacyInstructionsCard: View {
    @Binding var instructions: String
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("legacy.instructions.title", bundle: .module)
                .font(.kaso.titleMedium)
            TextEditor(text: $instructions)
                .frame(minHeight: Layout.instructionsHeight)
                .padding(Spacing.sm)
                .background(
                    Color.kaso.surfacePrimary,
                    in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                )
            Button {
                onSave()
            } label: {
                Text("legacy.instructions.save", bundle: .module)
            }
            .buttonStyle(.bordered)
        }
    }
}

private enum Layout {
    static let instructionsHeight: CGFloat = 120
}
