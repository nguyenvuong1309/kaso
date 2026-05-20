import BNPLDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct BNPLFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var obligations: IdentifiedArrayOf<BNPLObligation>
        public var summary: BNPLSummary
        public var monthlyIncome: Decimal
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingObligation: BNPLObligation?
        public var draftProvider: BNPLProvider
        public var draftPurchaseName: String
        public var draftTotalAmountText: String
        public var draftInstallmentCount: Int
        public var draftPurchaseDate: Date
        public var draftNote: String
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            obligations: IdentifiedArrayOf<BNPLObligation> = [],
            summary: BNPLSummary = .empty,
            monthlyIncome: Decimal = 0,
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingObligation: BNPLObligation? = nil,
            draftProvider: BNPLProvider = .shopeePayLater,
            draftPurchaseName: String = "",
            draftTotalAmountText: String = "",
            draftInstallmentCount: Int = 3,
            draftPurchaseDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            draftNote: String = "",
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.obligations = obligations
            self.summary = summary
            self.monthlyIncome = monthlyIncome
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingObligation = editingObligation
            self.draftProvider = draftProvider
            self.draftPurchaseName = draftPurchaseName
            self.draftTotalAmountText = draftTotalAmountText
            self.draftInstallmentCount = draftInstallmentCount
            self.draftPurchaseDate = draftPurchaseDate
            self.draftNote = draftNote
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(obligations: [BNPLObligation], income: Decimal)
        case loadFailed(String)
        case addButtonTapped
        case editButtonTapped(BNPLObligation)
        case editorDismissed
        case providerChanged(BNPLProvider)
        case purchaseNameChanged(String)
        case totalAmountTextChanged(String)
        case installmentCountChanged(Int)
        case purchaseDateChanged(Date)
        case noteChanged(String)
        case saveButtonTapped
        case obligationSaved(BNPLObligation)
        case saveFailed(String)
        case deleteButtonTapped(UUID)
        case obligationDeleted(UUID)
        case deleteFailed(String)
        case installmentToggled(obligationID: UUID, installmentID: UUID)
    }

    @Dependency(\.bnplRepository) private var repository
    @Dependency(\.bnplContextClient) private var contextClient
    @Dependency(\.date.now) private var now
    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    do {
                        let obligations = try await repository.fetchAll()
                        let income = (try? await contextClient.monthlyIncome()) ?? 0
                        await send(.dataLoaded(obligations: obligations, income: income))
                    } catch {
                        await send(.loadFailed("bnpl.error.loadFailed"))
                    }
                }

            case let .dataLoaded(obligations, income):
                state.isLoading = false
                state.obligations = IdentifiedArray(uniqueElements: obligations)
                state.monthlyIncome = income
                state.summary = BNPLSummaryBuilder.build(
                    obligations: obligations,
                    monthlyIncome: income,
                    referenceDate: now
                )
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none

            case .addButtonTapped:
                state.editingObligation = nil
                state.draftProvider = .shopeePayLater
                state.draftPurchaseName = ""
                state.draftTotalAmountText = ""
                state.draftInstallmentCount = 3
                state.draftPurchaseDate = now
                state.draftNote = ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(obligation):
                state.editingObligation = obligation
                state.draftProvider = obligation.provider
                state.draftPurchaseName = obligation.purchaseName
                state.draftTotalAmountText = obligation.totalAmount.description
                state.draftInstallmentCount = obligation.installmentCount
                state.draftPurchaseDate = obligation.purchaseDate
                state.draftNote = obligation.note ?? ""
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case .editorDismissed:
                state.isEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .providerChanged(provider):
                state.draftProvider = provider
                return .none

            case let .purchaseNameChanged(name):
                state.draftPurchaseName = name
                state.editorErrorMessageKey = nil
                return .none

            case let .totalAmountTextChanged(text):
                state.draftTotalAmountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .installmentCountChanged(count):
                state.draftInstallmentCount = max(1, min(36, count))
                return .none

            case let .purchaseDateChanged(date):
                state.draftPurchaseDate = date
                return .none

            case let .noteChanged(note):
                state.draftNote = note
                return .none

            case .saveButtonTapped:
                let name = state.draftPurchaseName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard name.isEmpty == false else {
                    state.editorErrorMessageKey = "bnpl.error.nameRequired"
                    return .none
                }
                let normalizedText = state.draftTotalAmountText.replacingOccurrences(of: ".", with: "")
                guard let total = Decimal(string: normalizedText, locale: nil), total > 0 else {
                    state.editorErrorMessageKey = "bnpl.error.invalidAmount"
                    return .none
                }
                let note = state.draftNote.trimmingCharacters(in: .whitespacesAndNewlines)
                let existingInstallments = state.editingObligation?.installments ?? []
                let installments = existingInstallments.isEmpty || state.editingObligation == nil
                    ? BNPLInstallmentBuilder.generateMonthly(
                        totalAmount: total,
                        installmentCount: state.draftInstallmentCount,
                        startDate: state.draftPurchaseDate
                    )
                    : existingInstallments

                let obligation = BNPLObligation(
                    id: state.editingObligation?.id ?? uuid(),
                    provider: state.draftProvider,
                    purchaseName: name,
                    totalAmount: total,
                    purchaseDate: state.draftPurchaseDate,
                    installmentCount: state.draftInstallmentCount,
                    installments: installments,
                    note: note.isEmpty ? nil : note
                )
                return .run { send in
                    do {
                        try await repository.save(obligation)
                        await send(.obligationSaved(obligation))
                    } catch {
                        await send(.saveFailed("bnpl.error.saveFailed"))
                    }
                }

            case let .obligationSaved(obligation):
                state.isEditorPresented = false
                state.obligations.updateOrAppend(obligation)
                refreshSummary(&state)
                return .none

            case let .saveFailed(key):
                state.editorErrorMessageKey = key
                return .none

            case let .deleteButtonTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.obligationDeleted(id))
                    } catch {
                        await send(.deleteFailed("bnpl.error.deleteFailed"))
                    }
                }

            case let .obligationDeleted(id):
                state.obligations.remove(id: id)
                refreshSummary(&state)
                return .none

            case let .deleteFailed(key):
                state.errorMessageKey = key
                return .none

            case let .installmentToggled(obligationID, installmentID):
                guard var obligation = state.obligations[id: obligationID],
                      let index = obligation.installments.firstIndex(where: { $0.id == installmentID })
                else {
                    return .none
                }
                obligation.installments[index].isPaid.toggle()
                state.obligations.updateOrAppend(obligation)
                refreshSummary(&state)
                let toSave = obligation
                return .run { _ in
                    try? await repository.save(toSave)
                }
            }
        }
    }

    private func refreshSummary(_ state: inout State) {
        state.summary = BNPLSummaryBuilder.build(
            obligations: Array(state.obligations),
            monthlyIncome: state.monthlyIncome,
            referenceDate: now
        )
    }
}

public extension BNPLSummary {
    static let empty = BNPLSummary(
        totalActiveObligations: 0,
        totalOutstanding: 0,
        currentMonthDue: 0,
        nextThreeMonthsDue: 0,
        overdueAmount: 0,
        health: .safe,
        exposureRatio: 0,
        monthlyExposures: [],
        nextInstallmentDate: nil
    )
}
