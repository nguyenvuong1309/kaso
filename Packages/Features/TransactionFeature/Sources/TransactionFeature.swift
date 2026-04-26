import ComposableArchitecture
import Foundation
import TransactionDomain

@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var transactions: IdentifiedArrayOf<Transaction>
        public var summary: MonthlyTransactionSummary
        public var isLoading: Bool
        public var isSaving: Bool
        public var isAddSheetPresented: Bool
        public var amountText: String
        public var draftKind: TransactionKind
        public var draftCategory: TransactionCategory
        public var draftOccurredAt: Date
        public var draftNote: String
        public var errorMessageKey: String?
        public var formErrorMessageKey: String?

        public init(
            transactions: IdentifiedArrayOf<Transaction> = [],
            summary: MonthlyTransactionSummary = .empty,
            isLoading: Bool = false,
            isSaving: Bool = false,
            isAddSheetPresented: Bool = false,
            amountText: String = "",
            draftKind: TransactionKind = .expense,
            draftCategory: TransactionCategory = .food,
            draftOccurredAt: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            errorMessageKey: String? = nil,
            formErrorMessageKey: String? = nil
        ) {
            self.transactions = transactions
            self.summary = summary
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.isAddSheetPresented = isAddSheetPresented
            self.amountText = amountText
            self.draftKind = draftKind
            self.draftCategory = draftCategory
            self.draftOccurredAt = draftOccurredAt
            self.draftNote = draftNote
            self.errorMessageKey = errorMessageKey
            self.formErrorMessageKey = formErrorMessageKey
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
    }

    @Dependency(\.date.now) private var now
    @Dependency(\.transactionRepository) private var repository
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let transactions = try await repository.fetchAll()
                        await send(.transactionsLoaded(transactions))
                    } catch {
                        await send(.loadFailed("transactions.error.loadFailed"))
                    }
                }

            case let .transactionsLoaded(transactions):
                state.isLoading = false
                state.transactions = IdentifiedArray(
                    uniqueElements: transactions.sorted { $0.occurredAt > $1.occurredAt }
                )
                updateSummary(&state)
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
                state.amountText = amountText
                state.formErrorMessageKey = nil
                return .none

            case let .kindChanged(kind):
                state.draftKind = kind
                state.draftCategory = TransactionCategory.defaultCategory(for: kind)
                state.formErrorMessageKey = nil
                return .none

            case let .categoryChanged(category):
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
                    note: note.isEmpty ? nil : note
                )
                return save(draft, state: &state)

            case let .saveDraft(draft):
                return save(draft, state: &state)

            case let .transactionSaved(transaction):
                state.isSaving = false
                state.isAddSheetPresented = false
                insert(transaction, into: &state)
                resetForm(&state, occurredAt: now)
                updateSummary(&state)
                return .none

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.errorMessageKey = messageKey
                state.formErrorMessageKey = messageKey
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
        state.formErrorMessageKey = nil
    }

    private func updateSummary(_ state: inout State) {
        state.summary = state.transactions.monthlySummary(containing: now)
    }
}
