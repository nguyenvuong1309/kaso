import ComposableArchitecture
import KasoDesignSystem
import SwiftUI
import TransactionDomain

public struct TransactionRootView: View {
    private let store: StoreOf<TransactionFeature>

    public init(repository: TransactionRepository = .empty) {
        store = Store(initialState: TransactionFeature.State()) {
            TransactionFeature()
        } withDependencies: {
            $0.transactionRepository = repository
        }
    }

    public var body: some View {
        TransactionView(store: store)
    }
}

public struct TransactionView: View {
    @Bindable private var store: StoreOf<TransactionFeature>
    private let onSignOutButtonTapped: (() -> Void)?

    public init(
        store: StoreOf<TransactionFeature>,
        onSignOutButtonTapped: (() -> Void)? = nil
    ) {
        self.store = store
        self.onSignOutButtonTapped = onSignOutButtonTapped
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    summarySection
                    recentTransactionsSection
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("transactions.title", bundle: .module))
            .toolbar {
                if let onSignOutButtonTapped {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .destructive) {
                            onSignOutButtonTapped()
                        } label: {
                            Label {
                                Text("transactions.account.signOut", bundle: .module)
                            } icon: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                        }
                        .accessibilityLabel(
                            Text("transactions.account.signOut", bundle: .module)
                        )
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("transactions.add.title", bundle: .module))
                }
            }
            .sheet(isPresented: addSheetPresented) {
                AddTransactionSheet(store: store)
            }
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var addSheetPresented: Binding<Bool> {
        Binding(
            get: { store.isAddSheetPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.addSheetDismissed)
                }
            }
        )
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("transactions.summary.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            VStack(spacing: Spacing.sm) {
                SummaryRow(
                    title: Text("transactions.summary.income", bundle: .module),
                    amount: store.summary.income,
                    color: Color.kaso.positive
                )
                SummaryRow(
                    title: Text("transactions.summary.expense", bundle: .module),
                    amount: store.summary.expense,
                    color: Color.kaso.destructive
                )
                SummaryRow(
                    title: Text("transactions.summary.balance", bundle: .module),
                    amount: store.summary.balance,
                    color: Color.kaso.accent
                )
            }
        }
    }

    private var recentTransactionsSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("transactions.recent.title", bundle: .module)
                    .font(.kaso.titleMedium)

                if let errorMessageKey = store.errorMessageKey {
                    Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }

                if store.transactions.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("transactions.empty.title", bundle: .module)
                        } icon: {
                            Image(systemName: "tray")
                        }
                    } description: {
                        Text("transactions.empty.description", bundle: .module)
                    }
                } else {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(store.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
        }
    }
}

private struct AddTransactionSheet: View {
    @Bindable var store: StoreOf<TransactionFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        selection: kindBinding,
                        label: Text("transactions.add.kind", bundle: .module)
                    ) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(LocalizedStringKey(kind.nameKey), bundle: .module)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(
                        text: amountBinding,
                        prompt: Text("transactions.add.amount.placeholder", bundle: .module)
                    ) {
                        Text("transactions.add.amount", bundle: .module)
                    }
                    .kasoDecimalKeyboard()
                } header: {
                    Text("transactions.add.amountSection", bundle: .module)
                }

                Section {
                    Picker(
                        selection: categoryBinding,
                        label: Text("transactions.add.category", bundle: .module)
                    ) {
                        ForEach(TransactionCategory.defaults(for: store.draftKind)) { category in
                            Label {
                                Text(LocalizedStringKey(category.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: category.symbolName)
                            }
                            .tag(category)
                        }
                    }

                    DatePicker(
                        selection: occurredAtBinding,
                        displayedComponents: [.date]
                    ) {
                        Text("transactions.add.date", bundle: .module)
                    }
                } header: {
                    Text("transactions.add.detailSection", bundle: .module)
                }

                Section {
                    TextField(
                        text: noteBinding,
                        prompt: Text("transactions.add.note.placeholder", bundle: .module),
                        axis: .vertical
                    ) {
                        Text("transactions.add.note", bundle: .module)
                    }
                    .lineLimit(2 ... 4)
                }

                if let formErrorMessageKey = store.formErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(formErrorMessageKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(Text("transactions.add.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.addSheetDismissed)
                    } label: {
                        Text("transactions.add.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        if store.isSaving {
                            ProgressView()
                        } else {
                            Text("transactions.add.save", bundle: .module)
                        }
                    }
                    .disabled(store.isSaving)
                }
            }
        }
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { store.amountText },
            set: { store.send(.amountTextChanged($0)) }
        )
    }

    private var kindBinding: Binding<TransactionKind> {
        Binding(
            get: { store.draftKind },
            set: { store.send(.kindChanged($0)) }
        )
    }

    private var categoryBinding: Binding<TransactionCategory> {
        Binding(
            get: { store.draftCategory },
            set: { store.send(.categoryChanged($0)) }
        )
    }

    private var occurredAtBinding: Binding<Date> {
        Binding(
            get: { store.draftOccurredAt },
            set: { store.send(.occurredAtChanged($0)) }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { store.draftNote },
            set: { store.send(.noteChanged($0)) }
        )
    }
}

private struct SummaryRow: View {
    let title: Text
    let amount: Decimal
    let color: Color

    var body: some View {
        HStack {
            title
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            Spacer(minLength: Spacing.md)

            Text(amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct TransactionRow: View {
    let transaction: TransactionDomain.Transaction

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: transaction.category.symbolName)
                .foregroundStyle(Color.kaso.accent)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(transaction.category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                if let note = transaction.note {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            Spacer(minLength: Spacing.md)

            Text(transaction.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(transaction.kind == .income ? Color.kaso.positive : Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, Spacing.sm)
    }
}

private extension View {
    @ViewBuilder
    func kasoDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

#Preview("Light") {
    TransactionView(
        store: Store(initialState: TransactionFeature.State()) {
            TransactionFeature()
        } withDependencies: {
            $0.transactionRepository = .preview
        }
    )
}

#Preview("Dark") {
    TransactionView(
        store: Store(initialState: TransactionFeature.State()) {
            TransactionFeature()
        } withDependencies: {
            $0.transactionRepository = .preview
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    TransactionView(
        store: Store(initialState: TransactionFeature.State()) {
            TransactionFeature()
        } withDependencies: {
            $0.transactionRepository = .preview
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
