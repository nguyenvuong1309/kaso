import Foundation
import ComposableArchitecture
import BudgetDomain
import TransactionDomain

public enum TransactionHistoryScope: String, CaseIterable, Equatable, Identifiable, Sendable {
    case all
    case day
    case week
    case month

    public var id: String {
        rawValue
    }

    public var nameKey: String {
        "transactions.history.scope.\(rawValue)"
    }

    func contains(
        _ date: Date,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> Bool {
        switch self {
        case .all:
            true
        case .day:
            calendar.isDate(date, inSameDayAs: referenceDate)
        case .week:
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear)
        case .month:
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        }
    }
}

public enum CustomCategoryOption: String, CaseIterable, Equatable, Identifiable, Sendable {
    case coffee
    case groceries
    case gift
    case pet
    case travel

    public var id: String {
        rawValue
    }

    public var symbolName: String {
        switch self {
        case .coffee:
            "cup.and.saucer"
        case .groceries:
            "cart"
        case .gift:
            "gift"
        case .pet:
            "pawprint"
        case .travel:
            "airplane"
        }
    }

    public var nameKey: String {
        "transactions.category.option.\(rawValue)"
    }

    public var colorName: String {
        switch self {
        case .coffee:
            "brown"
        case .groceries:
            "green"
        case .gift:
            "pink"
        case .pet:
            "orange"
        case .travel:
            "blue"
        }
    }
}

@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var transactions: IdentifiedArrayOf<Transaction>
        public var summary: MonthlyTransactionSummary
        public var categorySpendings: [MonthlyCategorySpending]
        public var budgets: [Budget]
        public var customCategories: [TransactionCategory]
        public var historyReferenceDate: Date
        public var historyScope: TransactionHistoryScope
        public var searchText: String
        public var selectedCategoryID: String?
        public var isLoading: Bool
        public var isSaving: Bool
        public var isBudgetSaving: Bool
        public var isCategorySaving: Bool
        public var isReceiptImageSaving: Bool
        public var isAddSheetPresented: Bool
        public var isBudgetEditorPresented: Bool
        public var isCategoryEditorPresented: Bool
        public var amountText: String
        public var budgetLimitText: String
        public var categoryNameText: String
        public var categoryOption: CustomCategoryOption
        public var editingBudgetCategory: TransactionCategory?
        public var draftKind: TransactionKind
        public var draftCategory: TransactionCategory
        public var draftOccurredAt: Date
        public var draftNote: String
        public var draftReceiptImageIdentifier: String?
        public var budgetEditorErrorMessageKey: String?
        public var categoryEditorErrorMessageKey: String?
        public var errorMessageKey: String?
        public var formErrorMessageKey: String?

        public init(
            transactions: IdentifiedArrayOf<Transaction> = [],
            summary: MonthlyTransactionSummary = .empty,
            categorySpendings: [MonthlyCategorySpending] = [],
            budgets: [Budget] = [],
            customCategories: [TransactionCategory] = [],
            historyReferenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            historyScope: TransactionHistoryScope = .all,
            searchText: String = "",
            selectedCategoryID: String? = nil,
            isLoading: Bool = false,
            isSaving: Bool = false,
            isBudgetSaving: Bool = false,
            isCategorySaving: Bool = false,
            isReceiptImageSaving: Bool = false,
            isAddSheetPresented: Bool = false,
            isBudgetEditorPresented: Bool = false,
            isCategoryEditorPresented: Bool = false,
            amountText: String = "",
            budgetLimitText: String = "",
            categoryNameText: String = "",
            categoryOption: CustomCategoryOption = .coffee,
            editingBudgetCategory: TransactionCategory? = nil,
            draftKind: TransactionKind = .expense,
            draftCategory: TransactionCategory = .food,
            draftOccurredAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            draftReceiptImageIdentifier: String? = nil,
            budgetEditorErrorMessageKey: String? = nil,
            categoryEditorErrorMessageKey: String? = nil,
            errorMessageKey: String? = nil,
            formErrorMessageKey: String? = nil
        ) {
            self.transactions = transactions
            self.summary = summary
            self.categorySpendings = categorySpendings
            self.budgets = budgets
            self.customCategories = customCategories
            self.historyReferenceDate = historyReferenceDate
            self.historyScope = historyScope
            self.searchText = searchText
            self.selectedCategoryID = selectedCategoryID
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.isBudgetSaving = isBudgetSaving
            self.isCategorySaving = isCategorySaving
            self.isReceiptImageSaving = isReceiptImageSaving
            self.isAddSheetPresented = isAddSheetPresented
            self.isBudgetEditorPresented = isBudgetEditorPresented
            self.isCategoryEditorPresented = isCategoryEditorPresented
            self.amountText = amountText
            self.budgetLimitText = budgetLimitText
            self.categoryNameText = categoryNameText
            self.categoryOption = categoryOption
            self.editingBudgetCategory = editingBudgetCategory
            self.draftKind = draftKind
            self.draftCategory = draftCategory
            self.draftOccurredAt = draftOccurredAt
            self.draftNote = draftNote
            self.draftReceiptImageIdentifier = draftReceiptImageIdentifier
            self.budgetEditorErrorMessageKey = budgetEditorErrorMessageKey
            self.categoryEditorErrorMessageKey = categoryEditorErrorMessageKey
            self.errorMessageKey = errorMessageKey
            self.formErrorMessageKey = formErrorMessageKey
        }

        public var filterCategories: [TransactionCategory] {
            Self.uniqueCategories(
                TransactionCategory.defaultExpenseCategories
                    + TransactionCategory.defaultIncomeCategories
                    + customCategories
            )
        }

        public func categories(for kind: TransactionKind) -> [TransactionCategory] {
            switch kind {
            case .income:
                TransactionCategory.defaultIncomeCategories
            case .expense:
                Self.uniqueCategories(
                    TransactionCategory.defaultExpenseCategories + customCategories
                )
            }
        }

        public var draftCategories: [TransactionCategory] {
            categories(for: draftKind)
        }

        public var filteredTransactions: [Transaction] {
            let normalizedQuery = searchText.normalizedForTransactionSearch

            return transactions.filter { transaction in
                let matchesCategory = selectedCategoryID == nil
                    || transaction.category.id == selectedCategoryID
                let matchesScope = historyScope.contains(
                    transaction.occurredAt,
                    referenceDate: historyReferenceDate
                )
                let matchesSearch = normalizedQuery.isEmpty
                    || transaction.matchesSearch(normalizedQuery)

                return matchesCategory && matchesScope && matchesSearch
            }
        }

        private static func uniqueCategories(
            _ categories: [TransactionCategory]
        ) -> [TransactionCategory] {
            var seenCategoryIDs: Set<String> = []
            return categories.filter { category in
                seenCategoryIDs.insert(category.id).inserted
            }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case transactionsLoaded([Transaction])
        case loadFailed(String)
        case addButtonTapped
        case addSheetDismissed
        case amountTextChanged(String)
        case kindChanged(TransactionKind)
        case categoryChanged(TransactionCategory)
        case occurredAtChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case saveDraft(TransactionDraft)
        case transactionSaved(Transaction)
        case saveFailed(String)
        case budgetsUpdated([Budget])
        case budgetsLoaded([Budget])
        case budgetEditButtonTapped(Budget)
        case budgetEditorDismissed
        case budgetLimitTextChanged(String)
        case budgetSaveButtonTapped
        case budgetsSaved([Budget])
        case budgetSaveFailed(String)
        case customCategoriesLoaded([TransactionCategory])
        case categoryAddButtonTapped
        case categoryEditorDismissed
        case categoryNameTextChanged(String)
        case categoryOptionChanged(CustomCategoryOption)
        case categorySaveButtonTapped
        case customCategoriesSaved([TransactionCategory], TransactionCategory)
        case categorySaveFailed(String)
        case searchTextChanged(String)
        case historyScopeChanged(TransactionHistoryScope)
        case categoryFilterChanged(String?)
        case receiptImageDataSelected(Data)
        case receiptImageSaved(String)
        case receiptImageSaveFailed(String)
        case receiptImageRemoved
    }

    @Dependency(\.budgetRepository) private var budgetRepository
    @Dependency(\.date.now) private var now
    @Dependency(\.receiptImageRepository) private var receiptImageRepository
    @Dependency(\.transactionCategoryRepository) private var categoryRepository
    @Dependency(\.transactionRepository) private var repository
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.historyReferenceDate = now
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let transactions = try await repository.fetchAll()
                        await send(.transactionsLoaded(transactions))
                    } catch {
                        await send(.loadFailed("transactions.error.loadFailed"))
                    }

                    do {
                        let budgets = try await budgetRepository.fetchAll()
                        if budgets.isEmpty == false {
                            await send(.budgetsLoaded(budgets))
                        }
                    } catch {
                        await send(.budgetSaveFailed("transactions.budget.error.loadFailed"))
                    }

                    do {
                        let categories = try await categoryRepository.fetchCustomCategories()
                        if categories.isEmpty == false {
                            await send(.customCategoriesLoaded(categories))
                        }
                    } catch {
                        await send(.categorySaveFailed("transactions.category.error.loadFailed"))
                    }
                }

            case let .transactionsLoaded(transactions):
                state.isLoading = false
                state.transactions = IdentifiedArray(
                    uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
                )
                updateDashboard(&state)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .addButtonTapped:
                resetForm(&state, occurredAt: now)
                state.isAddSheetPresented = true
                return .none

            case .addSheetDismissed:
                state.isAddSheetPresented = false
                state.formErrorMessageKey = nil
                return .none

            case let .amountTextChanged(amountText):
                state.amountText = TransactionAmountFormatter.formatForEditing(amountText)
                state.formErrorMessageKey = nil
                return .none

            case let .kindChanged(kind):
                state.draftKind = kind
                state.draftCategory = state.categories(for: kind).first
                    ?? TransactionCategory.defaultCategory(for: kind)
                state.formErrorMessageKey = nil
                return .none

            case let .categoryChanged(category):
                guard state.categories(for: state.draftKind).contains(category) else {
                    return .none
                }

                state.draftCategory = category
                state.formErrorMessageKey = nil
                return .none

            case let .occurredAtChanged(date):
                state.draftOccurredAt = date
                return .none

            case let .noteChanged(note):
                state.draftNote = note
                return .none

            case .saveButtonTapped:
                guard let amount = TransactionAmountParser.parse(state.amountText) else {
                    state.formErrorMessageKey = "transactions.add.error.invalidAmount"
                    return .none
                }

                let note = state.draftNote
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let draft = TransactionDraft(
                    amount: amount,
                    kind: state.draftKind,
                    category: state.draftCategory,
                    occurredAt: state.draftOccurredAt,
                    note: note.isEmpty ? nil : note,
                    receiptImageIdentifier: state.draftReceiptImageIdentifier
                )
                return save(draft, state: &state)

            case let .saveDraft(draft):
                return save(draft, state: &state)

            case let .transactionSaved(transaction):
                state.isSaving = false
                state.isAddSheetPresented = false
                insert(transaction, into: &state)
                resetForm(&state, occurredAt: now)
                updateDashboard(&state)
                return .none

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.errorMessageKey = messageKey
                state.formErrorMessageKey = messageKey
                return .none

            case let .budgetsUpdated(budgets):
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                return .none

            case let .budgetsLoaded(budgets):
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                return .none

            case let .budgetEditButtonTapped(budget):
                state.editingBudgetCategory = budget.category
                state.budgetLimitText = TransactionAmountFormatter.formatForEditing(
                    budget.monthlyLimit.description
                )
                state.budgetEditorErrorMessageKey = nil
                state.isBudgetEditorPresented = true
                return .none

            case .budgetEditorDismissed:
                resetBudgetEditor(&state)
                return .none

            case let .budgetLimitTextChanged(text):
                state.budgetLimitText = TransactionAmountFormatter.formatForEditing(text)
                state.budgetEditorErrorMessageKey = nil
                return .none

            case .budgetSaveButtonTapped:
                guard let category = state.editingBudgetCategory else {
                    return .none
                }

                guard let monthlyLimit = TransactionAmountParser.parse(state.budgetLimitText),
                      monthlyLimit > 0
                else {
                    state.budgetEditorErrorMessageKey = "transactions.budget.edit.error.invalidLimit"
                    return .none
                }

                let budgets = updatingBudgets(
                    state.budgets,
                    category: category,
                    monthlyLimit: monthlyLimit
                )
                let budgetsToSave = budgets.map {
                    Budget(category: $0.category, monthlyLimit: $0.monthlyLimit)
                }

                state.isBudgetSaving = true
                state.budgetEditorErrorMessageKey = nil

                return .run { send in
                    do {
                        try await budgetRepository.saveAll(budgetsToSave)
                        await send(.budgetsSaved(budgetsToSave))
                    } catch {
                        await send(.budgetSaveFailed("transactions.budget.error.saveFailed"))
                    }
                }

            case let .budgetsSaved(budgets):
                state.isBudgetSaving = false
                state.budgets = budgets.applyingMonthlySpending(
                    from: Array(state.transactions),
                    containing: now
                )
                resetBudgetEditor(&state)
                return .none

            case let .budgetSaveFailed(messageKey):
                state.isBudgetSaving = false
                state.budgetEditorErrorMessageKey = messageKey
                return .none

            case let .searchTextChanged(searchText):
                state.searchText = searchText
                return .none

            case let .historyScopeChanged(scope):
                state.historyScope = scope
                state.historyReferenceDate = now
                return .none

            case let .categoryFilterChanged(categoryID):
                if let categoryID,
                   state.filterCategories.contains(where: { $0.id == categoryID }) == false {
                    return .none
                }

                state.selectedCategoryID = categoryID
                return .none

            case let .customCategoriesLoaded(categories):
                state.customCategories = categories
                return .none

            case .categoryAddButtonTapped:
                resetCategoryEditor(&state)
                state.isCategoryEditorPresented = true
                return .none

            case .categoryEditorDismissed:
                resetCategoryEditor(&state)
                return .none

            case let .categoryNameTextChanged(text):
                state.categoryNameText = text
                state.categoryEditorErrorMessageKey = nil
                return .none

            case let .categoryOptionChanged(option):
                state.categoryOption = option
                state.categoryEditorErrorMessageKey = nil
                return .none

            case .categorySaveButtonTapped:
                let name = state.categoryNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.isEmpty == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.nameRequired"
                    return .none
                }

                let normalizedName = name.normalizedForCategoryID
                guard normalizedName.isEmpty == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.nameRequired"
                    return .none
                }

                let categoryID = "custom-\(normalizedName)"
                guard state.filterCategories.contains(where: { $0.id == categoryID }) == false else {
                    state.categoryEditorErrorMessageKey = "transactions.category.error.duplicate"
                    return .none
                }

                let category = TransactionCategory(
                    id: categoryID,
                    nameKey: name,
                    symbolName: state.categoryOption.symbolName,
                    colorName: state.categoryOption.colorName
                )
                let categories = (state.customCategories + [category])
                    .sorted { $0.nameKey < $1.nameKey }

                state.isCategorySaving = true
                state.categoryEditorErrorMessageKey = nil

                return .run { send in
                    do {
                        try await categoryRepository.saveCustomCategories(categories)
                        await send(.customCategoriesSaved(categories, category))
                    } catch {
                        await send(.categorySaveFailed("transactions.category.error.saveFailed"))
                    }
                }

            case let .customCategoriesSaved(categories, category):
                state.customCategories = categories
                state.draftKind = .expense
                state.draftCategory = category
                resetCategoryEditor(&state)
                return .none

            case let .categorySaveFailed(messageKey):
                state.isCategorySaving = false
                state.categoryEditorErrorMessageKey = messageKey
                return .none

            case let .receiptImageDataSelected(data):
                guard data.isEmpty == false else {
                    return .none
                }

                state.isReceiptImageSaving = true
                state.formErrorMessageKey = nil

                return .run { send in
                    do {
                        let identifier = try await receiptImageRepository.save(data)
                        await send(.receiptImageSaved(identifier))
                    } catch {
                        await send(.receiptImageSaveFailed("transactions.add.receipt.error.saveFailed"))
                    }
                }

            case let .receiptImageSaved(identifier):
                state.isReceiptImageSaving = false
                state.draftReceiptImageIdentifier = identifier
                return .none

            case let .receiptImageSaveFailed(messageKey):
                state.isReceiptImageSaving = false
                state.formErrorMessageKey = messageKey
                return .none

            case .receiptImageRemoved:
                state.draftReceiptImageIdentifier = nil
                state.formErrorMessageKey = nil
                return .none
            }
        }
    }

    private func save(
        _ draft: TransactionDraft,
        state: inout State
    ) -> Effect<Action> {
        do {
            let transaction = try draft.validated(id: uuid())
            state.isSaving = true
            state.errorMessageKey = nil
            state.formErrorMessageKey = nil

            return .run { send in
                do {
                    try await repository.save(transaction)
                    await send(.transactionSaved(transaction))
                } catch {
                    await send(.saveFailed("transactions.error.saveFailed"))
                }
            }
        } catch {
            state.errorMessageKey = "transactions.error.invalidDraft"
            state.formErrorMessageKey = "transactions.error.invalidDraft"
            return .none
        }
    }

    private func insert(
        _ transaction: Transaction,
        into state: inout State
    ) {
        var transactions = Array(state.transactions)
        transactions.removeAll { $0.id == transaction.id }
        transactions.append(transaction)
        state.transactions = IdentifiedArray(
            uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
        )
    }

    private func resetForm(
        _ state: inout State,
        occurredAt: Date
    ) {
        state.amountText = ""
        state.draftKind = .expense
        state.draftCategory = TransactionCategory.defaultCategory(for: .expense)
        state.draftOccurredAt = occurredAt
        state.draftNote = ""
        state.draftReceiptImageIdentifier = nil
        state.isReceiptImageSaving = false
        state.formErrorMessageKey = nil
    }

    private func resetCategoryEditor(_ state: inout State) {
        state.isCategoryEditorPresented = false
        state.isCategorySaving = false
        state.categoryNameText = ""
        state.categoryOption = .coffee
        state.categoryEditorErrorMessageKey = nil
    }

    private func resetBudgetEditor(_ state: inout State) {
        state.isBudgetEditorPresented = false
        state.isBudgetSaving = false
        state.editingBudgetCategory = nil
        state.budgetLimitText = ""
        state.budgetEditorErrorMessageKey = nil
    }

    private func updatingBudgets(
        _ budgets: [Budget],
        category: TransactionCategory,
        monthlyLimit: Decimal
    ) -> [Budget] {
        var updatedBudgets = budgets
        if let index = updatedBudgets.firstIndex(where: { $0.category.id == category.id }) {
            updatedBudgets[index].monthlyLimit = monthlyLimit
        } else {
            updatedBudgets.append(Budget(category: category, monthlyLimit: monthlyLimit))
        }

        return updatedBudgets.sorted { $0.category.id < $1.category.id }
    }

    private func updateDashboard(_ state: inout State) {
        state.summary = state.transactions.monthlySummary(containing: now)
        state.categorySpendings = state.transactions.monthlyCategorySpendings(containing: now)
        state.budgets = state.budgets.applyingMonthlySpending(
            from: Array(state.transactions),
            containing: now
        )
    }
}

private extension Transaction {
    func matchesSearch(_ normalizedQuery: String) -> Bool {
        let searchableValues = [
            note,
            category.id,
            category.nameKey,
            kind.rawValue,
            amount.description,
        ].compactMap { $0 }

        return searchableValues.contains {
            $0.normalizedForTransactionSearch.contains(normalizedQuery)
        }
    }
}

private extension String {
    var normalizedForTransactionSearch: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    var normalizedForCategoryID: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "-" }
            .reduce(into: "") { result, character in
                if character == "-", result.last == "-" {
                    return
                }

                result.append(character)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
