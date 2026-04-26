import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import WealthDomain

public struct WealthRootView: View {
    private let store: StoreOf<WealthFeature>

    public init(
        assetRepository: AssetRepository = .empty,
        liabilityRepository: LiabilityRepository = .empty,
        snapshotRepository: NetWorthSnapshotRepository = .empty
    ) {
        store = Store(initialState: WealthFeature.State()) {
            WealthFeature()
        } withDependencies: {
            $0.assetRepository = assetRepository
            $0.liabilityRepository = liabilityRepository
            $0.netWorthSnapshotRepository = snapshotRepository
        }
    }

    public var body: some View {
        WealthView(store: store)
    }
}

public struct WealthView: View {
    @Bindable private var store: StoreOf<WealthFeature>

    public init(store: StoreOf<WealthFeature>) {
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
                        WealthErrorLabel(messageKey: errorMessageKey)
                    }

                    KasoCard {
                        NetWorthSummaryCard(
                            snapshot: store.currentSnapshot,
                            growth: store.growth
                        )
                    }

                    KasoCard {
                        NetWorthHistoryCard(history: store.monthlyHistory)
                    }

                    KasoCard {
                        WealthBreakdownCard(breakdown: store.breakdown)
                    }

                    KasoCard {
                        WealthAssetSection(
                            assets: Array(store.assets),
                            onAddTapped: {
                                store.send(.assetAddButtonTapped)
                            },
                            onEditTapped: { asset in
                                store.send(.assetEditButtonTapped(asset))
                            },
                            onDeleteTapped: { asset in
                                store.send(.assetDeleteButtonTapped(asset))
                            }
                        )
                    }

                    KasoCard {
                        WealthLiabilitySection(
                            liabilities: Array(store.liabilities),
                            onAddTapped: {
                                store.send(.liabilityAddButtonTapped)
                            },
                            onEditTapped: { liability in
                                store.send(.liabilityEditButtonTapped(liability))
                            },
                            onDeleteTapped: { liability in
                                store.send(.liabilityDeleteButtonTapped(liability))
                            }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("wealth.title", bundle: .module))
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        store.send(.assetAddButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("wealth.asset.add", bundle: .module))

                    Button {
                        store.send(.liabilityAddButtonTapped)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .accessibilityLabel(Text("wealth.liability.add", bundle: .module))
                }
            }
            .sheet(isPresented: assetEditorPresented) {
                AssetEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: liabilityEditorPresented) {
                LiabilityEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var assetEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isAssetEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.assetEditorDismissed)
                }
            }
        )
    }

    private var liabilityEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isLiabilityEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.liabilityEditorDismissed)
                }
            }
        )
    }
}

private struct WealthErrorLabel: View {
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
