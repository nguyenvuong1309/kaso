import ComposableArchitecture
import KasoDesignSystem
import RoundUpDomain
import SwiftUI

public struct RoundUpRootView: View {
    private let store: StoreOf<RoundUpFeature>

    public init(repository: RoundUpRepository = .empty) {
        store = Store(initialState: RoundUpFeature.State()) {
            RoundUpFeature()
        } withDependencies: {
            $0.roundUpRepository = repository
        }
    }

    public var body: some View {
        RoundUpView(store: store)
    }
}

public struct RoundUpView: View {
    @Bindable private var store: StoreOf<RoundUpFeature>

    public init(store: StoreOf<RoundUpFeature>) {
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
                        RoundUpErrorLabel(messageKey: errorMessageKey)
                    }

                    KasoCard {
                        RoundUpSummaryCard(summary: store.summary, rule: store.rule)
                    }

                    KasoCard {
                        RoundUpRuleCard(
                            rule: store.rule,
                            isSaving: store.isSavingRule,
                            onToggle: { store.send(.toggleEnabled($0)) },
                            onStepChanged: { store.send(.stepChanged($0)) }
                        )
                    }

                    KasoCard {
                        RoundUpSimulatorCard(
                            amountText: $store.simulatorAmountText.sending(\.simulatorAmountChanged),
                            contribution: store.simulatorContribution,
                            step: store.rule.step
                        )
                    }

                    KasoCard {
                        RoundUpHistoryCard(
                            entries: store.summary.entries,
                            onManualAdd: { store.send(.manualEntryOpened) },
                            onDelete: { store.send(.entryDeleteRequested($0.id)) },
                            onClearAll: { store.send(.clearAllRequested) }
                        )
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("roundUp.title", bundle: .module))
            .sheet(isPresented: manualEntryPresented) {
                RoundUpManualEntrySheet(store: store)
                    .presentationDetents([.medium])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var manualEntryPresented: Binding<Bool> {
        Binding(
            get: { store.isManualEntryPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.manualEntryDismissed)
                }
            }
        )
    }
}

private struct RoundUpErrorLabel: View {
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
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
