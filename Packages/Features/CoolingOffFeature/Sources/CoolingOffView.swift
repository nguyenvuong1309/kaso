import ComposableArchitecture
import CoolingOffDomain
import KasoDesignSystem
import SwiftUI

public struct CoolingOffRootView: View {
    private let store: StoreOf<CoolingOffFeature>

    public init(repository: PurchasePlanRepository = .empty) {
        store = Store(initialState: CoolingOffFeature.State()) {
            CoolingOffFeature()
        } withDependencies: {
            $0.purchasePlanRepository = repository
        }
    }

    public var body: some View {
        CoolingOffView(store: store)
    }
}

public struct CoolingOffView: View {
    @Bindable private var store: StoreOf<CoolingOffFeature>

    public init(store: StoreOf<CoolingOffFeature>) {
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
                        CoolingOffErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        CoolingOffSummaryCard(summary: store.summary)
                    }

                    if store.summary.ready.isEmpty == false {
                        KasoCard {
                            CoolingOffPlanSectionCard(
                                titleKey: "coolingOff.section.ready",
                                subtitleKey: "coolingOff.section.ready.subtitle",
                                plans: store.summary.ready,
                                referenceDate: store.referenceDate,
                                showActions: true,
                                onApprove: { store.send(.approveTapped($0.id)) },
                                onCancel: { store.send(.cancelTapped($0.id)) },
                                onEdit: { store.send(.editButtonTapped($0)) },
                                onDelete: { store.send(.deleteTapped($0.id)) }
                            )
                        }
                    }

                    KasoCard {
                        CoolingOffPlanSectionCard(
                            titleKey: "coolingOff.section.waiting",
                            subtitleKey: "coolingOff.section.waiting.subtitle",
                            plans: store.summary.waiting,
                            referenceDate: store.referenceDate,
                            showActions: false,
                            onApprove: { _ in },
                            onCancel: { store.send(.cancelTapped($0.id)) },
                            onEdit: { store.send(.editButtonTapped($0)) },
                            onDelete: { store.send(.deleteTapped($0.id)) },
                            emptyMessageKey: "coolingOff.section.waiting.empty"
                        )
                    }

                    if store.summary.decided.isEmpty == false {
                        KasoCard {
                            CoolingOffPlanSectionCard(
                                titleKey: "coolingOff.section.history",
                                subtitleKey: "coolingOff.section.history.subtitle",
                                plans: Array(store.summary.decided.prefix(12)),
                                referenceDate: store.referenceDate,
                                showActions: false,
                                onApprove: { _ in },
                                onCancel: { _ in },
                                onEdit: { _ in },
                                onDelete: { store.send(.deleteTapped($0.id)) }
                            )
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("coolingOff.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("coolingOff.add", bundle: .module))
                }
            }
            .sheet(isPresented: editorPresented) {
                CoolingOffEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var editorPresented: Binding<Bool> {
        Binding(
            get: { store.isEditorPresented },
            set: { presented in
                if presented == false {
                    store.send(.editorDismissed)
                }
            }
        )
    }
}

private struct CoolingOffErrorLabel: View {
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
