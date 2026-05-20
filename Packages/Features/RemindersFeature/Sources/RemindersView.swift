import ComposableArchitecture
import KasoDesignSystem
import RemindersDomain
import SwiftUI

public struct RemindersRootView: View {
    private let store: StoreOf<RemindersFeature>

    public init(
        repository: ReminderRepository = .empty,
        scheduler: ReminderScheduler = .empty
    ) {
        store = Store(initialState: RemindersFeature.State()) {
            RemindersFeature()
        } withDependencies: {
            $0.reminderRepository = repository
            $0.reminderScheduler = scheduler
        }
    }

    public var body: some View {
        RemindersView(store: store)
    }
}

public struct RemindersView: View {
    private let store: StoreOf<RemindersFeature>

    public init(store: StoreOf<RemindersFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if store.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                }

                KasoCard {
                    RemindersHeaderCard(
                        authorizationStatus: store.authorizationStatus,
                        onRequest: { store.send(.authorizationRequested) }
                    )
                }

                ForEach(ReminderKind.allCases) { kind in
                    KasoCard {
                        ReminderRowCard(
                            kind: kind,
                            preference: store.configuration.preference(for: kind),
                            onToggle: { isOn in
                                store.send(.enabledToggled(kind: kind, isOn: isOn))
                            },
                            onTimeChange: { hour, minute in
                                store.send(
                                    .timeChanged(kind: kind, hour: hour, minute: minute)
                                )
                            }
                        )
                    }
                }

                if let messageKey = store.errorMessageKey {
                    RemindersErrorLabel(messageKey: messageKey)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
    }
}

private struct RemindersErrorLabel: View {
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
