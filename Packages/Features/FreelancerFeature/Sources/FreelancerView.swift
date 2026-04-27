import SwiftUI
import ComposableArchitecture
import FreelancerDomain
import KasoDesignSystem

public struct FreelancerRootView: View {
    private let store: StoreOf<FreelancerFeature>

    public init(repository: FreelancerProfileRepository = .empty) {
        store = Store(initialState: FreelancerFeature.State()) {
            FreelancerFeature()
        } withDependencies: {
            $0.freelancerProfileRepository = repository
        }
    }

    public var body: some View {
        FreelancerView(store: store)
    }
}

public struct FreelancerView: View {
    @Bindable private var store: StoreOf<FreelancerFeature>

    public init(store: StoreOf<FreelancerFeature>) {
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
                        FreelancerErrorLabel(messageKey: errorMessageKey)
                    }

                    FreelancerWindowPicker(
                        selectedWindow: $store.selectedWindow.sending(\.smoothingWindowChanged)
                    )

                    KasoCard {
                        FreelancerSmoothedIncomeCard(view: store.smoothedView)
                    }

                    KasoCard {
                        FreelancerBufferCard(view: store.smoothedView)
                    }

                    KasoCard {
                        FreelancerIncomeHistoryCard(incomes: store.incomeHistory)
                    }

                    KasoCard {
                        FreelancerReminderCard(reminders: store.reminders)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("freelancer.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.profileButtonTapped)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel(Text("freelancer.profile", bundle: .module))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addIncomeButtonTapped)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("freelancer.addIncome", bundle: .module))
                }
            }
            .sheet(isPresented: incomeEditorPresented) {
                FreelancerIncomeEditorSheet(store: store)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: profileEditorPresented) {
                FreelancerProfileEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var incomeEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isIncomeEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.incomeEditorDismissed)
                }
            }
        )
    }

    private var profileEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isProfileEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.profileEditorDismissed)
                }
            }
        )
    }
}

private struct FreelancerErrorLabel: View {
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
            Color.kaso.destructive.opacity(Layout.alertOpacity),
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
    }
}

private enum Layout {
    static let alertOpacity: Double = 0.12
}
