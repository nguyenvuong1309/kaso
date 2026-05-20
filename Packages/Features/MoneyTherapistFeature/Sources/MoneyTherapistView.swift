import ComposableArchitecture
import KasoDesignSystem
import MoneyTherapistDomain
import SwiftUI

public struct MoneyTherapistRootView: View {
    private let store: StoreOf<MoneyTherapistFeature>

    public init(repository: TherapistRepository = .empty) {
        store = Store(initialState: MoneyTherapistFeature.State()) {
            MoneyTherapistFeature()
        } withDependencies: {
            $0.therapistRepository = repository
        }
    }

    public var body: some View {
        MoneyTherapistView(store: store)
    }
}

public struct MoneyTherapistView: View {
    @Bindable private var store: StoreOf<MoneyTherapistFeature>

    public init(store: StoreOf<MoneyTherapistFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if store.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                KasoCard {
                    MoneyTherapistHeaderCard()
                }

                KasoCard {
                    MoneyTherapistTopicsCard(
                        onSelect: { store.send(.topicSelected($0)) }
                    )
                }

                if store.reflections.isEmpty == false {
                    KasoCard {
                        MoneyTherapistHistoryCard(
                            reflections: Array(store.reflections),
                            onDelete: { store.send(.deleteButtonTapped($0.id)) }
                        )
                    }
                }

                if let messageKey = store.errorMessageKey {
                    MoneyTherapistErrorLabel(messageKey: messageKey)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .sheet(isPresented: sheetPresented) {
            if let prompt = store.activePrompt {
                MoneyTherapistReflectionSheet(
                    prompt: prompt,
                    noteText: $store.noteText.sending(\.noteChanged),
                    onSave: { store.send(.saveButtonTapped) },
                    onCancel: { store.send(.sheetDismissed) }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }

    private var sheetPresented: Binding<Bool> {
        Binding(
            get: { store.activeTopic != nil },
            set: { presented in
                if presented == false {
                    store.send(.sheetDismissed)
                }
            }
        )
    }
}

private struct MoneyTherapistErrorLabel: View {
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
