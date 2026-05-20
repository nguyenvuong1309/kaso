import SwiftUI
import ComposableArchitecture
import InvestmentDomain
import KasoDesignSystem

public struct InvestmentRootView: View {
    private let store: StoreOf<InvestmentFeature>

    public init(
        holdingRepository: HoldingRepository = .empty,
        priceQuoteRepository: PriceQuoteRepository = .empty,
        targetAllocationRepository: TargetAllocationRepository = .empty,
        assetSyncClient: InvestmentAssetSyncClient = .empty
    ) {
        store = Store(initialState: InvestmentFeature.State()) {
            InvestmentFeature()
        } withDependencies: {
            $0.holdingRepository = holdingRepository
            $0.priceQuoteRepository = priceQuoteRepository
            $0.targetAllocationRepository = targetAllocationRepository
            $0.investmentAssetSyncClient = assetSyncClient
        }
    }

    public var body: some View {
        InvestmentView(store: store)
    }
}

public struct InvestmentView: View {
    @Bindable private var store: StoreOf<InvestmentFeature>

    public init(store: StoreOf<InvestmentFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let errorMessageKey = store.errorMessageKey {
                        InvestmentErrorLabel(messageKey: errorMessageKey)
                    }

                    KasoCard {
                        InvestmentSummaryCard(metrics: store.metrics)
                    }

                    KasoCard {
                        InvestmentAllocationCard(breakdown: store.allocationBreakdown)
                    }

                    KasoCard {
                        InvestmentRebalanceCard(
                            target: store.targetAllocation,
                            suggestion: store.rebalanceSuggestion,
                            onEditTargetTapped: {
                                store.send(.targetEditButtonTapped)
                            }
                        )
                    }

                    KasoCard {
                        InvestmentHoldingSection(
                            holdings: Array(store.holdings),
                            metrics: store.metrics.holdingMetrics,
                            onAddTapped: {
                                store.send(.holdingAddButtonTapped)
                            },
                            onEditTapped: { holding in
                                store.send(.holdingEditButtonTapped(holding))
                            },
                            onDeleteTapped: { holding in
                                store.send(.holdingDeleteButtonTapped(holding))
                            }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("investment.title", bundle: .module))
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        store.send(.refreshPricesButtonTapped)
                    } label: {
                        if store.isRefreshingPrices {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(store.isRefreshingPrices || store.holdings.isEmpty)
                    .accessibilityLabel(Text("investment.price.refresh", bundle: .module))

                    Button {
                        store.send(.targetEditButtonTapped)
                    } label: {
                        Image(systemName: "target")
                    }
                    .accessibilityLabel(Text("investment.target.edit", bundle: .module))

                    Button {
                        store.send(.holdingAddButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("investment.holding.add", bundle: .module))
                }
            }
            .sheet(isPresented: holdingEditorPresented) {
                InvestmentHoldingEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: targetEditorPresented) {
                InvestmentTargetEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var holdingEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isHoldingEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.holdingEditorDismissed)
                }
            }
        )
    }

    private var targetEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isTargetEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.targetEditorDismissed)
                }
            }
        )
    }
}

private struct InvestmentErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kaso.destructive)
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(Layout.alertBackgroundOpacity))
        )
    }
}

private enum Layout {
    static let alertBackgroundOpacity: Double = 0.12
}
