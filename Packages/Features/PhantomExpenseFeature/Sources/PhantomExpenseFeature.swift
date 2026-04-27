import Foundation
import ComposableArchitecture
import PhantomExpenseDomain

@Reducer
public struct PhantomExpenseFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var expenses: IdentifiedArrayOf<PhantomExpense>
        public var referenceDate: Date
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var isSaving: Bool
        public var editingExpenseID: UUID?
        public var titleText: String
        public var amountText: String
        public var category: PhantomExpenseCategory
        public var avoidedAt: Date
        public var noteText: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            expenses: IdentifiedArrayOf<PhantomExpense> = [],
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            isSaving: Bool = false,
            editingExpenseID: UUID? = nil,
            titleText: String = "",
            amountText: String = "",
            category: PhantomExpenseCategory = .cart,
            avoidedAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            noteText: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.expenses = expenses
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.isSaving = isSaving
            self.editingExpenseID = editingExpenseID
            self.titleText = titleText
            self.amountText = amountText
            self.category = category
            self.avoidedAt = avoidedAt
            self.noteText = noteText
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }

        public var monthlySummary: PhantomExpenseMonthlySummary {
            PhantomExpenseSummaryBuilder.monthly(
                expenses: Array(expenses),
                referenceDate: referenceDate
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case expensesLoaded([PhantomExpense])
        case loadFailed(String)
        case addButtonTapped
        case editButtonTapped(PhantomExpense)
        case editorDismissed
        case titleTextChanged(String)
        case amountTextChanged(String)
        case categoryChanged(PhantomExpenseCategory)
        case avoidedAtChanged(Date)
        case noteTextChanged(String)
        case saveButtonTapped
        case expenseSaved(PhantomExpense)
        case saveFailed(String)
        case deleteButtonTapped(PhantomExpense)
        case expenseDeleted(UUID)
        case deleteFailed(String)
    }

    @Dependency(\.phantomExpenseRepository) private var repository
    @Dependency(\.date) private var date
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.referenceDate = date.now
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        await send(.expensesLoaded(try await repository.fetchAll()))
                    } catch {
                        await send(.loadFailed("phantom.error.loadFailed"))
                    }
                }

            case let .expensesLoaded(expenses):
                state.isLoading = false
                state.expenses = IdentifiedArray(uniqueElements: Self.sortedExpenses(expenses))
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .addButtonTapped:
                resetPhantomExpenseEditor(&state, avoidedAt: date.now)
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(expense):
                populatePhantomExpenseEditor(&state, expense: expense)
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                return .none

            case let .titleTextChanged(text):
                state.titleText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .amountTextChanged(text):
                state.amountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .categoryChanged(category):
                state.category = category
                state.editorErrorMessageKey = nil
                return .none

            case let .avoidedAtChanged(avoidedAt):
                state.avoidedAt = avoidedAt
                state.editorErrorMessageKey = nil
                return .none

            case let .noteTextChanged(text):
                state.noteText = text
                state.editorErrorMessageKey = nil
                return .none

            case .saveButtonTapped:
                return saveExpenseEffect(&state)

            case let .expenseSaved(expense):
                state.isSaving = false
                state.isEditorPresented = false
                state.expenses.remove(id: expense.id)
                state.expenses.append(expense)
                state.expenses = IdentifiedArray(uniqueElements: Self.sortedExpenses(Array(state.expenses)))
                clearPhantomExpenseEditor(&state)
                return .none

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.editorErrorMessageKey = messageKey
                return .none

            case let .deleteButtonTapped(expense):
                return .run { send in
                    do {
                        try await repository.delete(expense.id)
                        await send(.expenseDeleted(expense.id))
                    } catch {
                        await send(.deleteFailed("phantom.error.deleteFailed"))
                    }
                }

            case let .expenseDeleted(id):
                state.expenses.remove(id: id)
                return .none

            case let .deleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveExpenseEffect(_ state: inout State) -> Effect<Action> {
        guard let amount = PhantomExpenseFeatureFormatters.parseAmount(state.amountText) else {
            state.editorErrorMessageKey = "phantom.error.invalidAmount"
            return .none
        }

        let draft = PhantomExpenseDraft(
            title: state.titleText,
            amount: amount,
            category: state.category,
            avoidedAt: state.avoidedAt,
            note: state.noteText
        )

        do {
            let expense: PhantomExpense
            if let id = state.editingExpenseID, let existing = state.expenses[id: id] {
                expense = try draft.updating(existing: existing)
            } else {
                expense = try draft.validated(id: uuid(), createdAt: date.now)
            }
            state.isSaving = true
            return .run { send in
                do {
                    try await repository.save(expense)
                    await send(.expenseSaved(expense))
                } catch {
                    await send(.saveFailed("phantom.error.saveFailed"))
                }
            }
        } catch let error as PhantomExpenseValidationError {
            state.editorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.editorErrorMessageKey = "phantom.error.saveFailed"
            return .none
        }
    }

    private static func sortedExpenses(_ expenses: [PhantomExpense]) -> [PhantomExpense] {
        expenses.sorted {
            if $0.avoidedAt == $1.avoidedAt {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            } else {
                $0.avoidedAt > $1.avoidedAt
            }
        }
    }
}
