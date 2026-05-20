import BudgetFlowDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct BudgetFlowRootView: View {
    private let store: StoreOf<BudgetFlowFeature>

    public init(provider: BudgetFlowProvider = .empty) {
        store = Store(initialState: BudgetFlowFeature.State()) {
            BudgetFlowFeature()
        } withDependencies: {
            $0.budgetFlowProvider = provider
        }
    }

    public var body: some View {
        BudgetFlowView(store: store)
    }
}

public struct BudgetFlowView: View {
    @Bindable private var store: StoreOf<BudgetFlowFeature>

    public init(store: StoreOf<BudgetFlowFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }

                    if let messageKey = store.errorMessageKey {
                        BudgetFlowErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        BudgetFlowHeaderCard(
                            flow: store.flow,
                            displayMode: store.displayMode,
                            onModeChange: { store.send(.displayModeSelected($0)) }
                        )
                    }

                    KasoCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("budgetFlow.section.flow", bundle: .module)
                                .font(.kaso.titleMedium)

                            BudgetFlowSankeyCanvas(
                                flow: store.flow,
                                displayMode: store.displayMode,
                                selectedNodeID: store.selectedNodeID,
                                onTap: { store.send(.nodeTapped($0)) },
                                onClear: { store.send(.selectionCleared) }
                            )
                        }
                    }

                    if let node = store.selectedNode {
                        KasoCard {
                            BudgetFlowSelectionCard(
                                node: node,
                                currencyCode: store.flow.currencyCode
                            )
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("budgetFlow.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
        }
    }
}

struct BudgetFlowHeaderCard: View {
    let flow: BudgetFlow
    let displayMode: BudgetFlowDisplayMode
    let onModeChange: (BudgetFlowDisplayMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("budgetFlow.header.total", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            Text(BudgetFlowFormatters.amount(flow.total, currencyCode: flow.currencyCode))
                .font(.kaso.titleLarge)

            Picker(selection: pickerBinding) {
                ForEach(BudgetFlowDisplayMode.allCases) { mode in
                    Text(LocalizedStringKey(mode.titleKey), bundle: .module).tag(mode)
                }
            } label: {
                Text("budgetFlow.mode.title", bundle: .module)
            }
            .pickerStyle(.segmented)
        }
    }

    private var pickerBinding: Binding<BudgetFlowDisplayMode> {
        Binding(
            get: { displayMode },
            set: { onModeChange($0) }
        )
    }
}

struct BudgetFlowSelectionCard: View {
    let node: BudgetFlowNode
    let currencyCode: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.kaso.category(named: node.colorName).opacity(0.18))
                Image(systemName: node.symbolName)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.category(named: node.colorName))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(node.labelKey), bundle: .module)
                    .font(.kaso.titleMedium)
                Text(BudgetFlowFormatters.amount(node.amount, currencyCode: currencyCode))
                    .font(.kaso.numericMedium)
                Text(BudgetFlowFormatters.percent(node.ratio))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
            Spacer()
        }
    }
}

private struct BudgetFlowErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}

#Preview("Sample data") {
    BudgetFlowRootView(provider: .sample)
}
