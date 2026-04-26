import Charts
import Foundation
import PhotosUI
import SwiftUI
import ComposableArchitecture
import BudgetDomain
import KasoDesignSystem
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAnimatedIn = false
    @State private var hasCapturedInitialTransactionIDs = false
    @State private var knownTransactionIDs: Set<UUID> = []
    @State private var highlightedTransactionID: UUID?
    @State private var chartRevealProgress = 0.0
    private let onAppearanceButtonTapped: (() -> Void)?
    private let onSignOutButtonTapped: (() -> Void)?

    public init(
        store: StoreOf<TransactionFeature>,
        onAppearanceButtonTapped: (() -> Void)? = nil,
        onSignOutButtonTapped: (() -> Void)? = nil
    ) {
        self.store = store
        self.onAppearanceButtonTapped = onAppearanceButtonTapped
        self.onSignOutButtonTapped = onSignOutButtonTapped
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    summarySection
                        .homeEntrance(
                            isVisible: hasAnimatedIn,
                            delay: Layout.summaryEntranceDelay
                        )
                    categoryBreakdownSection
                        .homeEntrance(
                            isVisible: hasAnimatedIn,
                            delay: Layout.breakdownEntranceDelay
                        )
                    budgetSection
                        .homeEntrance(
                            isVisible: hasAnimatedIn,
                            delay: Layout.budgetEntranceDelay
                        )
                    historySection
                        .homeEntrance(
                            isVisible: hasAnimatedIn,
                            delay: Layout.recentEntranceDelay
                        )
                }
                .padding(Spacing.md)
            }
            .background(TransactionHomeBackground())
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

                ToolbarItemGroup(placement: .primaryAction) {
                    if let onAppearanceButtonTapped {
                        Button {
                            onAppearanceButtonTapped()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel(
                            Text("transactions.appearance.title", bundle: .module)
                        )
                    }

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
                    .kasoAddSheetPresentation()
            }
            .sheet(isPresented: budgetEditorPresented) {
                BudgetEditorSheet(store: store)
                    .kasoAddSheetPresentation()
            }
            .sheet(isPresented: categoryEditorPresented) {
                CategoryEditorSheet(store: store)
                    .kasoAddSheetPresentation()
            }
            .onAppear {
                startEntranceAnimation()
                startChartReveal(for: store.categorySpendings)
            }
            .onChange(of: store.isLoading) { _, isLoading in
                captureInitialTransactionIDsIfNeeded(isLoading: isLoading)
            }
            .onChange(of: transactionIDs) { _, ids in
                handleTransactionIDsChanged(ids)
            }
            .onChange(of: store.categorySpendings) { _, categorySpendings in
                startChartReveal(for: categorySpendings)
            }
            .task(id: highlightedTransactionID) {
                await clearHighlightedTransaction()
            }
            .transactionSavedFeedback(trigger: highlightedTransactionID)
            .successfulSaveFeedback(
                trigger: store.isBudgetSaving,
                errorMessageKey: store.budgetEditorErrorMessageKey
            )
            .successfulSaveFeedback(
                trigger: store.isCategorySaving,
                errorMessageKey: store.categoryEditorErrorMessageKey
            )
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

    private var budgetEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isBudgetEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.budgetEditorDismissed)
                }
            }
        )
    }

    private var categoryEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isCategoryEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.categoryEditorDismissed)
                }
            }
        )
    }

    private var summarySection: some View {
        KasoCard {
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
        .homeMovingBorderGlow(
            cornerRadius: Radius.lg,
            isActive: store.summary != .empty
        )
    }

    private var historySection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("transactions.history.title", bundle: .module)
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
                    historyFilters

                    if historySections.isEmpty {
                        ContentUnavailableView {
                            Label {
                                Text("transactions.history.emptyFiltered.title", bundle: .module)
                            } icon: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                            }
                        } description: {
                            Text("transactions.history.emptyFiltered.description", bundle: .module)
                        }
                    } else {
                        LazyVStack(alignment: .leading, spacing: Spacing.md) {
                            ForEach(historySections) { section in
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text(section.date.formatted(.dateTime.day().month(.wide).year()))
                                        .font(.kaso.caption)
                                        .foregroundStyle(Color.kaso.textSecondary)

                                    ForEach(section.transactions) { transaction in
                                        TransactionRow(
                                            transaction: transaction,
                                            isHighlighted: highlightedTransactionID == transaction.id
                                        )
                                        .transition(transactionRowTransition)
                                    }
                                }
                            }
                        }
                        .animation(rowInsertionAnimation, value: filteredTransactionIDs)
                    }
                }
            }
        }
    }

    private var historyFilters: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.kaso.textSecondary)

                TextField(
                    text: searchTextBinding,
                    prompt: Text("transactions.history.search.placeholder", bundle: .module)
                ) {
                    Text("transactions.history.search.label", bundle: .module)
                }
                .kasoSearchTextInput()
                .autocorrectionDisabled()
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.kaso.surfaceSecondary)
            )

            Picker(
                selection: historyScopeBinding,
                label: Text("transactions.history.scope.label", bundle: .module)
            ) {
                ForEach(TransactionHistoryScope.allCases) { scope in
                    Text(LocalizedStringKey(scope.nameKey), bundle: .module)
                        .tag(scope)
                }
            }
            .pickerStyle(.segmented)

            Picker(
                selection: categoryFilterBinding,
                label: Text("transactions.history.category.label", bundle: .module)
            ) {
                Text("transactions.history.category.all", bundle: .module)
                    .tag(String?.none)

                ForEach(store.filterCategories) { category in
                    Label {
                        Text(LocalizedStringKey(category.nameKey), bundle: .module)
                    } icon: {
                        Image(systemName: category.symbolName)
                            .foregroundStyle(Color.kaso.category(named: category.colorName))
                    }
                    .tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var categoryBreakdownSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("transactions.breakdown.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                if store.categorySpendings.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("transactions.breakdown.empty.title", bundle: .module)
                        } icon: {
                            Image(systemName: "chart.pie")
                        }
                    } description: {
                        Text("transactions.breakdown.empty.description", bundle: .module)
                    }
                } else {
                    Chart(store.categorySpendings) { spending in
                        SectorMark(
                            angle: .value(
                                "transactions.breakdown.amount",
                                amountValue(spending.amount) * chartRevealScale
                            ),
                            innerRadius: .ratio(Layout.chartInnerRadiusRatio),
                            angularInset: Layout.chartAngularInset
                        )
                        .foregroundStyle(by: .value("category", spending.category.id))
                        .accessibilityLabel(
                            Text(LocalizedStringKey(spending.category.nameKey), bundle: .module)
                        )
                        .accessibilityValue(
                            Text(spending.amount.formatted(.currency(code: "VND")))
                        )
                    }
                    .chartForegroundStyleScale(
                        domain: store.categorySpendings.map(\.category.id),
                        range: store.categorySpendings.map {
                            Color.kaso.category(named: $0.category.colorName)
                        }
                    )
                    .chartLegend(.hidden)
                    .frame(height: Layout.categoryChartHeight)
                    .scaleEffect(chartScale)
                    .animation(chartRevealAnimation, value: chartRevealProgress)

                    VStack(spacing: Spacing.sm) {
                        ForEach(store.categorySpendings) { spending in
                            CategorySpendingRow(spending: spending)
                        }
                    }
                    .opacity(chartLegendOpacity)
                    .offset(y: chartLegendOffsetY)
                    .animation(chartRevealAnimation, value: chartRevealProgress)
                }
            }
        }
    }

    private var budgetSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("transactions.budget.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                if store.budgets.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("transactions.budget.empty.title", bundle: .module)
                        } icon: {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                        }
                    } description: {
                        Text("transactions.budget.empty.description", bundle: .module)
                    }
                } else {
                    VStack(spacing: Spacing.md) {
                        ForEach(store.budgets) { budget in
                            Button {
                                store.send(.budgetEditButtonTapped(budget))
                            } label: {
                                BudgetProgressRow(budget: budget)
                            }
                            .buttonStyle(.plain)
                            .transition(budgetRowTransition)
                        }
                    }
                    .animation(rowInsertionAnimation, value: store.budgets)
                }
            }
        }
    }

    private var transactionIDs: [UUID] {
        store.transactions.map { $0.id }
    }

    private var filteredTransactionIDs: [UUID] {
        store.filteredTransactions.map { $0.id }
    }

    private var historySections: [TransactionHistorySection] {
        let groupedTransactions = Dictionary(
            grouping: store.filteredTransactions,
            by: { Calendar.current.startOfDay(for: $0.occurredAt) }
        )

        return groupedTransactions
            .map { date, transactions in
                TransactionHistorySection(
                    date: date,
                    transactions: transactions.sorted { $0.occurredAt > $1.occurredAt }
                )
            }
            .sorted { $0.date > $1.date }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { store.searchText },
            set: { store.send(.searchTextChanged($0)) }
        )
    }

    private var historyScopeBinding: Binding<TransactionHistoryScope> {
        Binding(
            get: { store.historyScope },
            set: { store.send(.historyScopeChanged($0)) }
        )
    }

    private var categoryFilterBinding: Binding<String?> {
        Binding(
            get: { store.selectedCategoryID },
            set: { store.send(.categoryFilterChanged($0)) }
        )
    }

    private var chartRevealScale: Double {
        reduceMotion ? 1 : max(chartRevealProgress, Layout.chartMinimumRevealProgress)
    }

    private var chartScale: CGFloat {
        guard reduceMotion == false else {
            return 1
        }

        return Layout.chartInitialScale
            + (1 - Layout.chartInitialScale) * CGFloat(chartRevealProgress)
    }

    private var chartLegendOpacity: Double {
        reduceMotion ? 1 : chartRevealProgress
    }

    private var chartLegendOffsetY: CGFloat {
        reduceMotion ? 0 : Layout.chartLegendInitialOffsetY * CGFloat(1 - chartRevealProgress)
    }

    private var chartRevealAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .easeOut(duration: Layout.chartRevealDuration)
    }

    private var rowInsertionAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.rowInsertionResponse,
            dampingFraction: Layout.rowInsertionDampingFraction
        )
    }

    private var rowHighlightAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .easeOut(duration: Layout.rowHighlightFadeDuration)
    }

    private var transactionRowTransition: AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            )
        }
    }

    private var budgetRowTransition: AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .asymmetric(
                insertion: .scale(scale: Layout.rowTransitionInitialScale)
                    .combined(with: .opacity),
                removal: .opacity
            )
        }
    }

    private func startEntranceAnimation() {
        guard hasAnimatedIn == false else {
            return
        }

        hasAnimatedIn = true
    }

    private func startChartReveal(for categorySpendings: [MonthlyCategorySpending]) {
        guard categorySpendings.isEmpty == false else {
            chartRevealProgress = 0
            return
        }

        if reduceMotion {
            chartRevealProgress = 1
        } else {
            chartRevealProgress = 0
            withAnimation(chartRevealAnimation) {
                chartRevealProgress = 1
            }
        }
    }

    private func captureInitialTransactionIDsIfNeeded(isLoading: Bool) {
        guard isLoading == false, hasCapturedInitialTransactionIDs == false else {
            return
        }

        knownTransactionIDs = Set(transactionIDs)
        hasCapturedInitialTransactionIDs = true
    }

    private func handleTransactionIDsChanged(_ ids: [UUID]) {
        let currentIDs = Set(ids)

        guard hasCapturedInitialTransactionIDs else {
            knownTransactionIDs = currentIDs
            hasCapturedInitialTransactionIDs = true
            return
        }

        let insertedIDs = currentIDs.subtracting(knownTransactionIDs)
        knownTransactionIDs = currentIDs

        guard let insertedID = ids.first(where: { insertedIDs.contains($0) }) else {
            return
        }

        withAnimation(rowInsertionAnimation) {
            highlightedTransactionID = insertedID
        }
    }

    @MainActor
    private func clearHighlightedTransaction() async {
        guard let highlightedTransactionID else {
            return
        }

        try? await Task.sleep(for: .milliseconds(Layout.rowHighlightDurationMilliseconds))

        guard self.highlightedTransactionID == highlightedTransactionID else {
            return
        }

        withAnimation(rowHighlightAnimation) {
            self.highlightedTransactionID = nil
        }
    }
}

private struct TransactionKindPicker: View {
    let selection: Binding<TransactionKind>

    var body: some View {
        Picker(
            selection: selection,
            label: Text("transactions.add.kind", bundle: .module)
        ) {
            ForEach(TransactionKind.allCases) { kind in
                Text(LocalizedStringKey(kind.nameKey), bundle: .module)
                    .tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct TransactionCategoryPicker: View {
    let categories: [TransactionCategory]
    let selection: Binding<TransactionCategory>
    let showsAddButton: Bool
    let onAddButtonTapped: () -> Void

    var body: some View {
        Picker(
            selection: selection,
            label: Text("transactions.add.category", bundle: .module)
        ) {
            ForEach(categories) { category in
                Label {
                    Text(LocalizedStringKey(category.nameKey), bundle: .module)
                } icon: {
                    Image(systemName: category.symbolName)
                        .foregroundStyle(Color.kaso.category(named: category.colorName))
                }
                .tag(category)
            }
        }

        if showsAddButton {
            Button {
                onAddButtonTapped()
            } label: {
                Label {
                    Text("transactions.category.add", bundle: .module)
                } icon: {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
}

private struct CategoryEditorSheet: View {
    @Bindable var store: StoreOf<TransactionFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: categoryNameBinding,
                        prompt: Text("transactions.category.name.placeholder", bundle: .module)
                    ) {
                        Text("transactions.category.name", bundle: .module)
                    }

                    Picker(
                        selection: categoryOptionBinding,
                        label: Text("transactions.category.icon", bundle: .module)
                    ) {
                        ForEach(CustomCategoryOption.allCases) { option in
                            Label {
                                Text(LocalizedStringKey(option.nameKey), bundle: .module)
                            } icon: {
                                Image(systemName: option.symbolName)
                                    .foregroundStyle(Color.kaso.category(named: option.colorName))
                            }
                            .tag(option)
                        }
                    }
                } header: {
                    Text("transactions.category.section", bundle: .module)
                }

                if let messageKey = store.categoryEditorErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(messageKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(Text("transactions.category.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.categoryEditorDismissed)
                    } label: {
                        Text("transactions.add.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.categorySaveButtonTapped)
                    } label: {
                        if store.isCategorySaving {
                            ProgressView()
                        } else {
                            Text("transactions.add.save", bundle: .module)
                        }
                    }
                    .disabled(store.isCategorySaving)
                }
            }
        }
    }

    private var categoryNameBinding: Binding<String> {
        Binding(
            get: { store.categoryNameText },
            set: { store.send(.categoryNameTextChanged($0)) }
        )
    }

    private var categoryOptionBinding: Binding<CustomCategoryOption> {
        Binding(
            get: { store.categoryOption },
            set: { store.send(.categoryOptionChanged($0)) }
        )
    }
}

private struct BudgetEditorSheet: View {
    @Bindable var store: StoreOf<TransactionFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var budgetLimitText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let category = store.editingBudgetCategory {
                        Label {
                            Text(LocalizedStringKey(category.nameKey), bundle: .module)
                        } icon: {
                            Image(systemName: category.symbolName)
                                .foregroundStyle(Color.kaso.category(named: category.colorName))
                        }
                    }

                    TextField(
                        text: budgetLimitBinding,
                        prompt: Text("transactions.budget.edit.limit.placeholder", bundle: .module)
                    ) {
                        Text("transactions.budget.edit.limit", bundle: .module)
                    }
                    .font(.kaso.numericLarge)
                    .kasoAmountKeyboard()
                } header: {
                    Text("transactions.budget.edit.section", bundle: .module)
                }

                if let messageKey = store.budgetEditorErrorMessageKey {
                    Section {
                        Text(LocalizedStringKey(messageKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(Text("transactions.budget.edit.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.budgetEditorDismissed)
                    } label: {
                        Text("transactions.add.cancel", bundle: .module)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.budgetSaveButtonTapped)
                    } label: {
                        if store.isBudgetSaving {
                            ProgressView()
                                .transition(saveButtonTransition)
                        } else {
                            Text("transactions.add.save", bundle: .module)
                                .transition(saveButtonTransition)
                        }
                    }
                    .animation(saveButtonAnimation, value: store.isBudgetSaving)
                    .disabled(store.isBudgetSaving)
                }
            }
        }
        .onAppear {
            budgetLimitText = store.budgetLimitText
        }
        .onChange(of: store.budgetLimitText) { _, newValue in
            guard budgetLimitText != newValue else {
                return
            }

            budgetLimitText = newValue
        }
    }

    private var budgetLimitBinding: Binding<String> {
        Binding(
            get: { budgetLimitText },
            set: { newValue in
                let formattedValue = TransactionAmountFormatter.formatForEditing(newValue)
                budgetLimitText = formattedValue
                store.send(.budgetLimitTextChanged(formattedValue))
            }
        )
    }

    private var saveButtonTransition: AnyTransition {
        reduceMotion ? .opacity : .scale.combined(with: .opacity)
    }

    private var saveButtonAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.saveButtonResponse,
            dampingFraction: Layout.saveButtonDampingFraction
        )
    }
}

private struct TransactionHistorySection: Identifiable {
    let date: Date
    let transactions: [TransactionDomain.Transaction]

    var id: Date {
        date
    }
}

private struct AddTransactionSheet: View {
    @Bindable var store: StoreOf<TransactionFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var amountText = ""
    @State private var receiptPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TransactionKindPicker(selection: kindBinding)

                    TextField(
                        text: amountBinding,
                        prompt: Text("transactions.add.amount.placeholder", bundle: .module)
                    ) {
                        Text("transactions.add.amount", bundle: .module)
                    }
                    .kasoAmountKeyboard()
                } header: {
                    Text("transactions.add.amountSection", bundle: .module)
                }

                Section {
                    TransactionCategoryPicker(
                        categories: draftCategories,
                        selection: categoryBinding,
                        showsAddButton: showsCategoryAddButton,
                        onAddButtonTapped: {
                            store.send(.categoryAddButtonTapped)
                        }
                    )

                    DatePicker(
                        selection: occurredAtBinding,
                        displayedComponents: [.date, .hourAndMinute]
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

                Section {
                    PhotosPicker(
                        selection: $receiptPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label {
                            Text("transactions.add.receipt.attach", bundle: .module)
                        } icon: {
                            Image(systemName: "doc.viewfinder")
                        }
                    }
                    .disabled(store.isReceiptImageSaving)

                    if store.isReceiptImageSaving {
                        HStack {
                            ProgressView()
                            Text("transactions.add.receipt.saving", bundle: .module)
                                .font(.kaso.caption)
                                .foregroundStyle(Color.kaso.textSecondary)
                        }
                    } else if store.draftReceiptImageIdentifier != nil {
                        HStack {
                            Label {
                                Text("transactions.add.receipt.attached", bundle: .module)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.kaso.positive)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                store.send(.receiptImageRemoved)
                                receiptPickerItem = nil
                            } label: {
                                Text("transactions.add.receipt.remove", bundle: .module)
                            }
                        }
                    }
                } header: {
                    Text("transactions.add.receipt.section", bundle: .module)
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
                        saveButtonLabel
                    }
                    .animation(saveButtonAnimation, value: store.isSaving)
                    .disabled(store.isSaving || store.isReceiptImageSaving)
                }
            }
        }
        .onAppear {
            amountText = store.amountText
        }
        .onChange(of: store.amountText) { _, newValue in
            guard amountText != newValue else {
                return
            }

            amountText = newValue
        }
        .onChange(of: receiptPickerItem) { _, item in
            Task {
                await loadReceiptImage(from: item)
            }
        }
    }

    @ViewBuilder
    private var saveButtonLabel: some View {
        if store.isSaving {
            ProgressView()
                .transition(saveButtonTransition)
        } else {
            Text("transactions.add.save", bundle: .module)
                .transition(saveButtonTransition)
        }
    }

    private var saveButtonTransition: AnyTransition {
        reduceMotion ? .opacity : .scale.combined(with: .opacity)
    }

    private var saveButtonAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.saveButtonResponse,
            dampingFraction: Layout.saveButtonDampingFraction
        )
    }

    private var amountBinding: Binding<String> {
        Binding(
            get: { amountText },
            set: { newValue in
                let formattedValue = TransactionAmountFormatter.formatForEditing(newValue)
                amountText = formattedValue
                store.send(.amountTextChanged(formattedValue))
            }
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

    private var draftCategories: [TransactionCategory] {
        store.draftCategories
    }

    private var showsCategoryAddButton: Bool {
        store.draftKind == .expense
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

    @MainActor
    private func loadReceiptImage(from item: PhotosPickerItem?) async {
        guard let item else {
            return
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                store.send(.receiptImageDataSelected(data))
            }
        } catch {
            store.send(.receiptImageSaveFailed("transactions.add.receipt.error.loadFailed"))
        }

        receiptPickerItem = nil
    }
}

private struct TransactionHomeBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            background(phase: Layout.backgroundStaticPhase)
        } else {
            TimelineView(.animation(minimumInterval: Layout.backgroundFrameInterval)) { context in
                background(phase: phase(for: context.date))
            }
        }
    }

    private func background(phase: Double) -> some View {
        let accentOpacity = Layout.backgroundAccentBaseOpacity
            + Layout.backgroundAccentRangeOpacity * phase
        let secondaryOpacity = Layout.backgroundSecondaryBaseOpacity
            + Layout.backgroundSecondaryRangeOpacity * (1 - phase)
        let orbOpacity = Layout.backgroundOrbBaseOpacity
            + Layout.backgroundOrbRangeOpacity * phase

        return ZStack {
            Color.kaso.surfacePrimary

            LinearGradient(
                colors: [
                    Color.kaso.accent.opacity(accentOpacity),
                    Color.kaso.surfacePrimary,
                    Color.kaso.surfaceSecondary.opacity(secondaryOpacity),
                ],
                startPoint: UnitPoint(
                    x: Layout.backgroundStartX + Layout.backgroundStartRangeX * phase,
                    y: Layout.backgroundStartY
                ),
                endPoint: UnitPoint(
                    x: Layout.backgroundEndX,
                    y: Layout.backgroundEndY
                )
            )

            Circle()
                .fill(Color.kaso.accent.opacity(orbOpacity))
                .frame(
                    width: Layout.backgroundOrbSize,
                    height: Layout.backgroundOrbSize
                )
                .blur(radius: Layout.backgroundOrbBlur)
                .offset(
                    x: Layout.backgroundOrbOffsetX * CGFloat(phase),
                    y: Layout.backgroundOrbOffsetY * CGFloat(1 - phase)
                )
        }
        .ignoresSafeArea()
    }

    private func phase(for date: Date) -> Double {
        let cycle = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Layout.backgroundCycleDuration)
        return (sin(cycle / Layout.backgroundCycleDuration * 2 * Double.pi) + 1) / 2
    }
}

private struct SummaryRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: Text
    let amount: Decimal
    let color: Color

    var body: some View {
        HStack {
            title
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            Spacer(minLength: Spacing.md)

            amountLabel
        }
    }

    @ViewBuilder
    private var amountLabel: some View {
        let numericAmount = amountValue(amount)
        let label = Text(amount.formatted(.currency(code: "VND")))
            .font(.kaso.numericMedium)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(Layout.amountMinimumScaleFactor)

        if reduceMotion {
            label
        } else {
            label
                .contentTransition(.numericText(value: numericAmount))
                .animation(
                    .spring(
                        response: Layout.numericTextResponse,
                        dampingFraction: Layout.numericTextDampingFraction
                    ),
                    value: numericAmount
                )
        }
    }
}

private struct TransactionRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transaction: TransactionDomain.Transaction
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: transaction.category.symbolName)
                .foregroundStyle(Color.kaso.category(named: transaction.category.colorName))
                .frame(width: Layout.categoryIconSize, height: Layout.categoryIconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(transaction.category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                if let note = transaction.note {
                    Text(note)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }

                if transaction.receiptImageIdentifier != nil {
                    Label {
                        Text("transactions.receipt.attached", bundle: .module)
                    } icon: {
                        Image(systemName: "paperclip")
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            Spacer(minLength: Spacing.md)

            Text(transaction.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(transaction.kind == .income ? Color.kaso.positive : Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.accent.opacity(Layout.rowHighlightBackgroundOpacity))
                .opacity(isHighlighted ? 1 : 0)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(Color.kaso.accent)
                .frame(width: Layout.rowHighlightIndicatorWidth)
                .opacity(isHighlighted ? Layout.rowHighlightIndicatorOpacity : 0)
        }
        .scaleEffect(isHighlighted && reduceMotion == false ? Layout.rowHighlightScale : 1)
        .animation(
            reduceMotion ? nil : .spring(
                response: Layout.rowHighlightResponse,
                dampingFraction: Layout.rowHighlightDampingFraction
            ),
            value: isHighlighted
        )
    }
}

private struct CategorySpendingRow: View {
    let spending: MonthlyCategorySpending

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: spending.category.symbolName)
                .foregroundStyle(Color.kaso.category(named: spending.category.colorName))
                .frame(width: Layout.categoryIconSize, height: Layout.categoryIconSize)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(spending.category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                Text(spending.fraction.formatted(.percent.precision(.fractionLength(0))))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Spacer(minLength: Spacing.md)

            Text(spending.amount.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Layout.amountMinimumScaleFactor)
        }
    }
}

private struct BudgetProgressRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedProgress = 0.0
    let budget: Budget

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                Image(systemName: budget.category.symbolName)
                    .foregroundStyle(Color.kaso.category(named: budget.category.colorName))
                    .frame(width: Layout.categoryIconSize, height: Layout.categoryIconSize)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(budget.category.nameKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text(LocalizedStringKey(budget.status.nameKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(budget.status.color)
                }

                Spacer(minLength: Spacing.md)

                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(budget.spent.formatted(.currency(code: "VND")))
                        .font(.kaso.numericMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(Layout.amountMinimumScaleFactor)

                    Text(budget.monthlyLimit.formatted(.currency(code: "VND")))
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(Layout.amountMinimumScaleFactor)
                }
            }

            ProgressView(value: displayedProgress)
                .tint(budget.status.color)
                .accessibilityLabel(
                    Text(LocalizedStringKey(budget.category.nameKey), bundle: .module)
                )
                .accessibilityValue(
                    Text(budget.utilization.formatted(.percent.precision(.fractionLength(0))))
                )
        }
        .onAppear {
            updateDisplayedProgress()
        }
        .onChange(of: budget.progressValue) { _, _ in
            updateDisplayedProgress()
        }
    }

    private func updateDisplayedProgress() {
        if reduceMotion {
            displayedProgress = budget.progressValue
        } else {
            withAnimation(
                .spring(
                    response: Layout.budgetProgressResponse,
                    dampingFraction: Layout.budgetProgressDampingFraction
                )
            ) {
                displayedProgress = budget.progressValue
            }
        }
    }
}

private struct HomeMovingBorderGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cornerRadius: CGFloat
    let isActive: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                if reduceMotion {
                    border(progress: Layout.borderGlowStaticProgress)
                } else {
                    TimelineView(.animation(minimumInterval: Layout.borderGlowFrameInterval)) { context in
                        border(progress: progress(for: context.date))
                    }
                }
            }
        }
    }

    private func border(progress: Double) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    stops: [
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: 0
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: Layout.borderGlowLeadingLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowPeakOpacity),
                            location: Layout.borderGlowPeakLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowTailOpacity),
                            location: Layout.borderGlowTailLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: 1
                        ),
                    ],
                    center: .center,
                    startAngle: .degrees(progress * 360),
                    endAngle: .degrees(progress * 360 + 360)
                ),
                lineWidth: Layout.borderGlowWidth
            )
            .shadow(
                color: Color.kaso.accent.opacity(Layout.borderGlowShadowOpacity),
                radius: Layout.borderGlowShadowRadius
            )
    }

    private func progress(for date: Date) -> Double {
        date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Layout.borderGlowDuration)
            / Layout.borderGlowDuration
    }
}

private struct HomeEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : Layout.entranceInitialScale)
            .offset(y: isVisible ? 0 : Layout.entranceInitialOffsetY)
            .animation(entranceAnimation, value: isVisible)
    }

    private var entranceAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.entranceResponse,
            dampingFraction: Layout.entranceDampingFraction
        )
        .delay(delay)
    }
}

private enum Layout {
    static let amountMinimumScaleFactor: CGFloat = 0.8
    static let categoryChartHeight: CGFloat = 180
    static let categoryIconSize: CGFloat = 28
    static let chartAngularInset: CGFloat = 1
    static let chartInnerRadiusRatio: CGFloat = 0.58
    static let chartMinimumRevealProgress: Double = 0.001
    static let chartInitialScale: CGFloat = 0.97
    static let chartRevealDuration: Double = 0.68
    static let chartLegendInitialOffsetY: CGFloat = Spacing.sm

    static let summaryEntranceDelay: Double = 0
    static let breakdownEntranceDelay: Double = 0.08
    static let budgetEntranceDelay: Double = 0.16
    static let recentEntranceDelay: Double = 0.24
    static let entranceInitialScale: CGFloat = 0.97
    static let entranceInitialOffsetY: CGFloat = Spacing.md
    static let entranceResponse: Double = 0.5
    static let entranceDampingFraction: Double = 0.86

    static let numericTextResponse: Double = 0.42
    static let numericTextDampingFraction: Double = 0.88

    static let rowInsertionResponse: Double = 0.42
    static let rowInsertionDampingFraction: Double = 0.86
    static let rowTransitionInitialScale: CGFloat = 0.98
    static let rowHighlightDurationMilliseconds = 1_050
    static let rowHighlightFadeDuration: Double = 0.32
    static let rowHighlightBackgroundOpacity: Double = 0.14
    static let rowHighlightIndicatorWidth: CGFloat = 3
    static let rowHighlightIndicatorOpacity: Double = 0.78
    static let rowHighlightScale: CGFloat = 1.01
    static let rowHighlightResponse: Double = 0.34
    static let rowHighlightDampingFraction: Double = 0.82

    static let budgetProgressResponse: Double = 0.58
    static let budgetProgressDampingFraction: Double = 0.88
    static let saveButtonResponse: Double = 0.28
    static let saveButtonDampingFraction: Double = 0.9

    static let backgroundCycleDuration: Double = 8
    static let backgroundFrameInterval: Double = 1 / 30
    static let backgroundStaticPhase: Double = 0.5
    static let backgroundAccentBaseOpacity: Double = 0.08
    static let backgroundAccentRangeOpacity: Double = 0.04
    static let backgroundSecondaryBaseOpacity: Double = 0.44
    static let backgroundSecondaryRangeOpacity: Double = 0.08
    static let backgroundOrbBaseOpacity: Double = 0.04
    static let backgroundOrbRangeOpacity: Double = 0.03
    static let backgroundStartX: Double = 0.08
    static let backgroundStartRangeX: Double = 0.06
    static let backgroundStartY: Double = 0
    static let backgroundEndX: Double = 0.92
    static let backgroundEndY: Double = 1
    static let backgroundOrbSize: CGFloat = Spacing.xl * 5
    static let backgroundOrbBlur: CGFloat = Spacing.xl
    static let backgroundOrbOffsetX: CGFloat = Spacing.xl
    static let backgroundOrbOffsetY: CGFloat = -Spacing.lg

    static let borderGlowStaticProgress: Double = 0.12
    static let borderGlowDuration: Double = 5.2
    static let borderGlowFrameInterval: Double = 1 / 30
    static let borderGlowWidth: CGFloat = 1.25
    static let borderGlowBaseOpacity: Double = 0.12
    static let borderGlowPeakOpacity: Double = 0.58
    static let borderGlowTailOpacity: Double = 0.22
    static let borderGlowLeadingLocation: Double = 0.58
    static let borderGlowPeakLocation: Double = 0.72
    static let borderGlowTailLocation: Double = 0.82
    static let borderGlowShadowOpacity: Double = 0.12
    static let borderGlowShadowRadius: CGFloat = 8
}

private func amountValue(_ amount: Decimal) -> Double {
    NSDecimalNumber(decimal: amount).doubleValue
}

private extension Budget {
    var progressValue: Double {
        min(max(utilization, 0), 1)
    }
}

private extension BudgetStatus {
    var nameKey: String {
        switch self {
        case .healthy:
            "transactions.budget.status.healthy"
        case .nearLimit:
            "transactions.budget.status.nearLimit"
        case .exceeded:
            "transactions.budget.status.exceeded"
        }
    }

    var color: Color {
        switch self {
        case .healthy:
            Color.kaso.positive
        case .nearLimit:
            Color.kaso.warning
        case .exceeded:
            Color.kaso.destructive
        }
    }
}

private extension View {
    @ViewBuilder
    func kasoAmountKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func kasoSearchTextInput() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func kasoAddSheetPresentation() -> some View {
        #if os(iOS)
        presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        #else
        self
        #endif
    }

    func homeEntrance(
        isVisible: Bool,
        delay: Double
    ) -> some View {
        modifier(
            HomeEntranceModifier(
                isVisible: isVisible,
                delay: delay
            )
        )
    }

    func homeMovingBorderGlow(
        cornerRadius: CGFloat,
        isActive: Bool
    ) -> some View {
        modifier(
            HomeMovingBorderGlowModifier(
                cornerRadius: cornerRadius,
                isActive: isActive
            )
        )
    }

    @ViewBuilder
    func transactionSavedFeedback(trigger: UUID?) -> some View {
        #if os(iOS)
        sensoryFeedback(.success, trigger: trigger) { _, newValue in
            newValue != nil
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func successfulSaveFeedback(
        trigger: Bool,
        errorMessageKey: String?
    ) -> some View {
        #if os(iOS)
        sensoryFeedback(.success, trigger: trigger) { oldValue, newValue in
            oldValue && newValue == false && errorMessageKey == nil
        }
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
