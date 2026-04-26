import Foundation
import ComposableArchitecture
import DebtDomain

@Reducer
public struct DebtFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var debts: IdentifiedArrayOf<Debt>
        public var selectedDebtID: UUID?
        public var referenceDate: Date
        public var isLoading: Bool
        public var isDebtEditorPresented: Bool
        public var isDebtSaving: Bool
        public var editingDebtID: UUID?
        public var debtNameText: String
        public var debtPrincipalText: String
        public var debtAnnualRateText: String
        public var debtTermMonthsText: String
        public var debtStartDate: Date
        public var debtPaymentDayText: String
        public var debtMonthlyPaymentText: String
        public var debtType: DebtType
        public var debtNoteText: String
        public var extraMonthlyPaymentText: String
        public var oneTimeExtraPaymentText: String
        public var errorMessageKey: String?
        public var debtEditorErrorMessageKey: String?

        public init(
            debts: IdentifiedArrayOf<Debt> = [],
            selectedDebtID: UUID? = nil,
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isDebtEditorPresented: Bool = false,
            isDebtSaving: Bool = false,
            editingDebtID: UUID? = nil,
            debtNameText: String = "",
            debtPrincipalText: String = "",
            debtAnnualRateText: String = "",
            debtTermMonthsText: String = "12",
            debtStartDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            debtPaymentDayText: String = "1",
            debtMonthlyPaymentText: String = "",
            debtType: DebtType = .personalLoan,
            debtNoteText: String = "",
            extraMonthlyPaymentText: String = "",
            oneTimeExtraPaymentText: String = "",
            errorMessageKey: String? = nil,
            debtEditorErrorMessageKey: String? = nil
        ) {
            self.debts = debts
            self.selectedDebtID = selectedDebtID
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isDebtEditorPresented = isDebtEditorPresented
            self.isDebtSaving = isDebtSaving
            self.editingDebtID = editingDebtID
            self.debtNameText = debtNameText
            self.debtPrincipalText = debtPrincipalText
            self.debtAnnualRateText = debtAnnualRateText
            self.debtTermMonthsText = debtTermMonthsText
            self.debtStartDate = debtStartDate
            self.debtPaymentDayText = debtPaymentDayText
            self.debtMonthlyPaymentText = debtMonthlyPaymentText
            self.debtType = debtType
            self.debtNoteText = debtNoteText
            self.extraMonthlyPaymentText = extraMonthlyPaymentText
            self.oneTimeExtraPaymentText = oneTimeExtraPaymentText
            self.errorMessageKey = errorMessageKey
            self.debtEditorErrorMessageKey = debtEditorErrorMessageKey
        }

        public var summary: DebtSummary {
            DebtSummaryBuilder.make(debts: Array(debts), asOf: referenceDate)
        }

        public var selectedDebt: Debt? {
            guard let selectedDebtID else {
                return debts.first
            }
            return debts[id: selectedDebtID] ?? debts.first
        }

        public var selectedSchedule: AmortizationSchedule? {
            guard let selectedDebt else {
                return nil
            }
            return try? AmortizationCalculator.schedule(for: selectedDebt)
        }

        public var extraPaymentResult: ExtraPaymentResult? {
            guard
                let selectedDebt,
                let extraMonthly = DebtFeature.parseMoney(extraMonthlyPaymentText) ?? .some(0),
                let oneTime = DebtFeature.parseMoney(oneTimeExtraPaymentText) ?? .some(0)
            else {
                return nil
            }

            return try? ExtraPaymentSimulator.simulate(
                debt: selectedDebt,
                extraMonthly: extraMonthly,
                oneTime: oneTime
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case debtsLoaded([Debt])
        case loadFailed(String)
        case liabilitiesSynced
        case liabilitiesSyncFailed(String)
        case debtSelected(UUID?)
        case debtAddButtonTapped
        case debtEditButtonTapped(Debt)
        case debtEditorDismissed
        case debtNameTextChanged(String)
        case debtPrincipalTextChanged(String)
        case debtAnnualRateTextChanged(String)
        case debtTermMonthsTextChanged(String)
        case debtStartDateChanged(Date)
        case debtPaymentDayTextChanged(String)
        case debtMonthlyPaymentTextChanged(String)
        case debtTypeChanged(DebtType)
        case debtNoteTextChanged(String)
        case extraMonthlyPaymentTextChanged(String)
        case oneTimeExtraPaymentTextChanged(String)
        case debtSaveButtonTapped
        case debtSaved(Debt)
        case debtSaveFailed(String)
        case debtDeleteButtonTapped(Debt)
        case debtDeleted(UUID)
        case debtDeleteFailed(String)
    }

    @Dependency(\.debtRepository) private var debtRepository
    @Dependency(\.debtLiabilitySyncClient) private var liabilitySyncClient
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
                        await send(.debtsLoaded(try await debtRepository.fetchAll()))
                    } catch {
                        await send(.loadFailed("debt.error.loadFailed"))
                    }
                }

            case let .debtsLoaded(debts):
                state.isLoading = false
                state.debts = IdentifiedArray(uniqueElements: debts)
                state.selectedDebtID = state.selectedDebtID ?? debts.first?.id
                return syncLiabilitiesEffect(debts: Array(state.debts), asOf: state.referenceDate)

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .liabilitiesSynced:
                return .none

            case let .liabilitiesSyncFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .debtSelected(id):
                state.selectedDebtID = id
                return .none

            case .debtAddButtonTapped:
                resetDebtEditor(&state, startDate: date.now)
                state.isDebtEditorPresented = true
                return .none

            case let .debtEditButtonTapped(debt):
                populateDebtEditor(&state, debt: debt)
                state.isDebtEditorPresented = true
                return .none

            case .debtEditorDismissed:
                state.isDebtEditorPresented = false
                return .none

            case let .debtNameTextChanged(text):
                state.debtNameText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtPrincipalTextChanged(text):
                state.debtPrincipalText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtAnnualRateTextChanged(text):
                state.debtAnnualRateText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtTermMonthsTextChanged(text):
                state.debtTermMonthsText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtStartDateChanged(date):
                state.debtStartDate = date
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtPaymentDayTextChanged(text):
                state.debtPaymentDayText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtMonthlyPaymentTextChanged(text):
                state.debtMonthlyPaymentText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtTypeChanged(type):
                state.debtType = type
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .debtNoteTextChanged(text):
                state.debtNoteText = text
                state.debtEditorErrorMessageKey = nil
                return .none

            case let .extraMonthlyPaymentTextChanged(text):
                state.extraMonthlyPaymentText = text
                return .none

            case let .oneTimeExtraPaymentTextChanged(text):
                state.oneTimeExtraPaymentText = text
                return .none

            case .debtSaveButtonTapped:
                return saveDebtEffect(&state)

            case let .debtSaved(debt):
                state.isDebtSaving = false
                state.isDebtEditorPresented = false
                state.debts.remove(id: debt.id)
                state.debts.append(debt)
                state.debts.sort { $0.createdAt < $1.createdAt }
                state.selectedDebtID = debt.id
                clearDebtEditor(&state)
                return syncLiabilitiesEffect(debts: Array(state.debts), asOf: state.referenceDate)

            case let .debtSaveFailed(messageKey):
                state.isDebtSaving = false
                state.debtEditorErrorMessageKey = messageKey
                return .none

            case let .debtDeleteButtonTapped(debt):
                return .run { send in
                    do {
                        try await debtRepository.delete(debt.id)
                        await send(.debtDeleted(debt.id))
                    } catch {
                        await send(.debtDeleteFailed("debt.error.deleteFailed"))
                    }
                }

            case let .debtDeleted(id):
                state.debts.remove(id: id)
                if state.selectedDebtID == id {
                    state.selectedDebtID = state.debts.first?.id
                }
                return syncLiabilitiesEffect(debts: Array(state.debts), asOf: state.referenceDate)

            case let .debtDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveDebtEffect(_ state: inout State) -> Effect<Action> {
        guard let principal = Self.parseMoney(state.debtPrincipalText) else {
            state.debtEditorErrorMessageKey = "debt.error.invalidPrincipal"
            return .none
        }
        guard let annualRate = Self.parseDecimal(state.debtAnnualRateText) else {
            state.debtEditorErrorMessageKey = "debt.error.invalidAnnualRate"
            return .none
        }
        guard let termMonths = Int(state.debtTermMonthsText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            state.debtEditorErrorMessageKey = "debt.error.invalidTerm"
            return .none
        }
        guard let paymentDay = Int(state.debtPaymentDayText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            state.debtEditorErrorMessageKey = "debt.error.invalidPaymentDay"
            return .none
        }
        let monthlyOverride = Self.optionalMoney(state.debtMonthlyPaymentText)
        let draft = DebtDraft(
            name: state.debtNameText,
            type: state.debtType,
            principal: principal,
            annualInterestRatePercent: annualRate,
            termMonths: termMonths,
            startDate: state.debtStartDate,
            paymentDay: paymentDay,
            monthlyPaymentOverride: monthlyOverride,
            note: state.debtNoteText
        )

        do {
            let debt: Debt
            if let id = state.editingDebtID, let existing = state.debts[id: id] {
                debt = try draft.updating(existing: existing)
            } else {
                debt = try draft.validated(id: uuid(), createdAt: date.now)
            }
            state.isDebtSaving = true
            return .run { send in
                do {
                    try await debtRepository.save(debt)
                    await send(.debtSaved(debt))
                } catch {
                    await send(.debtSaveFailed("debt.error.saveFailed"))
                }
            }
        } catch let error as DebtValidationError {
            state.debtEditorErrorMessageKey = error.messageKey
            return .none
        } catch {
            state.debtEditorErrorMessageKey = "debt.error.saveFailed"
            return .none
        }
    }

    private func syncLiabilitiesEffect(debts: [Debt], asOf date: Date) -> Effect<Action> {
        let liabilities = debts.map { $0.toLiability(asOf: date) }
        return .run { send in
            do {
                try await liabilitySyncClient.replaceAutoTracked(liabilities)
                await send(.liabilitiesSynced)
            } catch {
                await send(.liabilitiesSyncFailed("debt.error.liabilitySyncFailed"))
            }
        }
    }

    static func optionalMoney(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : parseMoney(trimmed)
    }

    static func parseMoney(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func parseDecimal(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.isEmpty == false else {
            return nil
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
