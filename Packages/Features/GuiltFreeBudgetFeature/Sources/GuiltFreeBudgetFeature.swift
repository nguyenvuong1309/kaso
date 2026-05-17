import ComposableArchitecture
import Foundation
import GuiltFreeBudgetDomain

@Reducer
public struct GuiltFreeBudgetFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var configuration: GuiltFreeBudgetConfiguration
        public var referenceDate: Date
        public var isLoading: Bool
        public var isSaving: Bool
        public var isIncomeEditorPresented: Bool
        public var isFixedCostEditorPresented: Bool
        public var editingFixedCostID: UUID?
        public var incomeText: String
        public var savingsText: String
        public var emergencyText: String
        public var fixedCostNameText: String
        public var fixedCostAmountText: String
        public var fixedCostKind: GuiltFreeFixedCostKind
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            configuration: GuiltFreeBudgetConfiguration = GuiltFreeBudgetConfiguration(),
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isSaving: Bool = false,
            isIncomeEditorPresented: Bool = false,
            isFixedCostEditorPresented: Bool = false,
            editingFixedCostID: UUID? = nil,
            incomeText: String = "",
            savingsText: String = "",
            emergencyText: String = "",
            fixedCostNameText: String = "",
            fixedCostAmountText: String = "",
            fixedCostKind: GuiltFreeFixedCostKind = .other,
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.configuration = configuration
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.isIncomeEditorPresented = isIncomeEditorPresented
            self.isFixedCostEditorPresented = isFixedCostEditorPresented
            self.editingFixedCostID = editingFixedCostID
            self.incomeText = incomeText
            self.savingsText = savingsText
            self.emergencyText = emergencyText
            self.fixedCostNameText = fixedCostNameText
            self.fixedCostAmountText = fixedCostAmountText
            self.fixedCostKind = fixedCostKind
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }

        public var budget: GuiltFreeBudget {
            GuiltFreeBudgetCalculator.calculate(configuration)
        }

        public var dailyAllowance: Decimal {
            GuiltFreeBudgetCalculator.dailyAllowance(
                from: budget,
                referenceDate: referenceDate
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case configurationLoaded(GuiltFreeBudgetConfiguration)
        case loadFailed(String)
        case incomeEditorOpened
        case incomeEditorDismissed
        case incomeTextChanged(String)
        case savingsTextChanged(String)
        case emergencyTextChanged(String)
        case incomeSaveTapped
        case fixedCostEditorOpenedNew
        case fixedCostEditorOpenedExisting(UUID)
        case fixedCostEditorDismissed
        case fixedCostNameChanged(String)
        case fixedCostAmountChanged(String)
        case fixedCostKindChanged(GuiltFreeFixedCostKind)
        case fixedCostSaveTapped
        case fixedCostDeleteTapped(UUID)
        case configurationSaved(GuiltFreeBudgetConfiguration)
        case saveFailed(String)
    }

    @Dependency(\.guiltFreeBudgetRepository) private var repository
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
                        let config = try await repository.load()
                        await send(.configurationLoaded(config))
                    } catch {
                        await send(.loadFailed("guiltFree.error.loadFailed"))
                    }
                }

            case let .configurationLoaded(config):
                state.isLoading = false
                state.configuration = config
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .incomeEditorOpened:
                state.incomeText = format(state.configuration.monthlyIncome)
                state.savingsText = format(state.configuration.monthlySavingsTarget)
                state.emergencyText = format(state.configuration.emergencyFundMonthlyContribution)
                state.editorErrorMessageKey = nil
                state.isIncomeEditorPresented = true
                return .none

            case .incomeEditorDismissed:
                state.isIncomeEditorPresented = false
                return .none

            case let .incomeTextChanged(text):
                state.incomeText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .savingsTextChanged(text):
                state.savingsText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .emergencyTextChanged(text):
                state.emergencyText = text
                state.editorErrorMessageKey = nil
                return .none

            case .incomeSaveTapped:
                guard let income = parse(state.incomeText), income >= 0 else {
                    state.editorErrorMessageKey = "guiltFree.error.invalidAmount"
                    return .none
                }
                let savings = parse(state.savingsText) ?? 0
                let emergency = parse(state.emergencyText) ?? 0
                guard savings >= 0, emergency >= 0 else {
                    state.editorErrorMessageKey = "guiltFree.error.invalidAmount"
                    return .none
                }
                var updated = state.configuration
                updated.monthlyIncome = income
                updated.monthlySavingsTarget = savings
                updated.emergencyFundMonthlyContribution = emergency
                updated.updatedAt = date.now
                state.isIncomeEditorPresented = false
                return saveEffect(updated, state: &state)

            case .fixedCostEditorOpenedNew:
                state.editingFixedCostID = nil
                state.fixedCostNameText = ""
                state.fixedCostAmountText = ""
                state.fixedCostKind = .other
                state.editorErrorMessageKey = nil
                state.isFixedCostEditorPresented = true
                return .none

            case let .fixedCostEditorOpenedExisting(id):
                guard let cost = state.configuration.fixedCosts.first(where: { $0.id == id }) else {
                    return .none
                }
                state.editingFixedCostID = id
                state.fixedCostNameText = cost.name
                state.fixedCostAmountText = format(cost.amount)
                state.fixedCostKind = cost.kind
                state.editorErrorMessageKey = nil
                state.isFixedCostEditorPresented = true
                return .none

            case .fixedCostEditorDismissed:
                state.isFixedCostEditorPresented = false
                return .none

            case let .fixedCostNameChanged(text):
                state.fixedCostNameText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .fixedCostAmountChanged(text):
                state.fixedCostAmountText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .fixedCostKindChanged(kind):
                state.fixedCostKind = kind
                state.editorErrorMessageKey = nil
                return .none

            case .fixedCostSaveTapped:
                let trimmedName = state.fixedCostNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedName.isEmpty == false else {
                    state.editorErrorMessageKey = "guiltFree.error.nameRequired"
                    return .none
                }
                guard let amount = parse(state.fixedCostAmountText), amount > 0 else {
                    state.editorErrorMessageKey = "guiltFree.error.invalidAmount"
                    return .none
                }
                var updated = state.configuration
                if let id = state.editingFixedCostID, let index = updated.fixedCosts.firstIndex(where: { $0.id == id }) {
                    var existing = updated.fixedCosts[index]
                    existing.name = trimmedName
                    existing.amount = amount
                    existing.kind = state.fixedCostKind
                    updated.fixedCosts[index] = existing
                } else {
                    updated.fixedCosts.append(
                        GuiltFreeFixedCost(
                            id: uuid(),
                            name: trimmedName,
                            amount: amount,
                            kind: state.fixedCostKind
                        )
                    )
                }
                updated.updatedAt = date.now
                state.isFixedCostEditorPresented = false
                return saveEffect(updated, state: &state)

            case let .fixedCostDeleteTapped(id):
                var updated = state.configuration
                updated.fixedCosts.removeAll { $0.id == id }
                updated.updatedAt = date.now
                return saveEffect(updated, state: &state)

            case let .configurationSaved(config):
                state.isSaving = false
                state.configuration = config
                return .none

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveEffect(_ config: GuiltFreeBudgetConfiguration, state: inout State) -> Effect<Action> {
        state.isSaving = true
        state.configuration = config
        return .run { send in
            do {
                try await repository.save(config)
                await send(.configurationSaved(config))
            } catch {
                await send(.saveFailed("guiltFree.error.saveFailed"))
            }
        }
    }

    private func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return 0
        }
        return Decimal(string: cleaned)
    }

    private func format(_ amount: Decimal) -> String {
        guard amount > 0 else {
            return ""
        }
        return amount.formatted(.number.grouping(.automatic))
    }
}
