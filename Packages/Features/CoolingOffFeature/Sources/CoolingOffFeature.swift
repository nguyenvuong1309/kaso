import ComposableArchitecture
import CoolingOffDomain
import Foundation

@Reducer
public struct CoolingOffFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var plans: IdentifiedArrayOf<PurchasePlan>
        public var policy: CoolingOffPolicy
        public var referenceDate: Date
        public var isLoading: Bool
        public var isEditorPresented: Bool
        public var editingPlanID: UUID?
        public var titleText: String
        public var amountText: String
        public var category: PurchasePlanCategory
        public var coolingPeriod: CoolingPeriod
        public var noteText: String
        public var coolingPeriodOverride: Bool
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            plans: IdentifiedArrayOf<PurchasePlan> = [],
            policy: CoolingOffPolicy = .default,
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            isEditorPresented: Bool = false,
            editingPlanID: UUID? = nil,
            titleText: String = "",
            amountText: String = "",
            category: PurchasePlanCategory = .other,
            coolingPeriod: CoolingPeriod = .threeDays,
            noteText: String = "",
            coolingPeriodOverride: Bool = false,
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.plans = plans
            self.policy = policy
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.isEditorPresented = isEditorPresented
            self.editingPlanID = editingPlanID
            self.titleText = titleText
            self.amountText = amountText
            self.category = category
            self.coolingPeriod = coolingPeriod
            self.noteText = noteText
            self.coolingPeriodOverride = coolingPeriodOverride
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }

        public var summary: PurchasePlanSummary {
            PurchasePlanSummaryBuilder.build(
                plans: Array(plans),
                referenceDate: referenceDate
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(plans: [PurchasePlan], policy: CoolingOffPolicy)
        case loadFailed(String)
        case tick(Date)
        case addButtonTapped
        case editButtonTapped(PurchasePlan)
        case editorDismissed
        case titleTextChanged(String)
        case amountTextChanged(String)
        case categoryChanged(PurchasePlanCategory)
        case coolingPeriodChanged(CoolingPeriod)
        case noteTextChanged(String)
        case useSuggestedPeriodTapped
        case saveButtonTapped
        case planSaved(PurchasePlan)
        case planSaveFailed(String)
        case approveTapped(UUID)
        case cancelTapped(UUID)
        case deleteTapped(UUID)
        case planDeleted(UUID)
        case planDeleteFailed(String)
    }

    @Dependency(\.purchasePlanRepository) private var repository
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
                        async let plans = repository.fetchAll()
                        async let policy = repository.loadPolicy()
                        await send(.dataLoaded(plans: try await plans, policy: try await policy))
                    } catch {
                        await send(.loadFailed("coolingOff.error.loadFailed"))
                    }
                }

            case let .dataLoaded(plans, policy):
                state.isLoading = false
                state.plans = IdentifiedArray(uniqueElements: plans)
                state.policy = policy
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .tick(now):
                state.referenceDate = now
                return .none

            case .addButtonTapped:
                state.editingPlanID = nil
                state.titleText = ""
                state.amountText = ""
                state.category = .other
                state.coolingPeriod = state.policy.defaultPeriod
                state.noteText = ""
                state.coolingPeriodOverride = false
                state.editorErrorMessageKey = nil
                state.isEditorPresented = true
                return .none

            case let .editButtonTapped(plan):
                state.editingPlanID = plan.id
                state.titleText = plan.title
                state.amountText = plan.amount.formatted(.number.grouping(.automatic))
                state.category = plan.category
                state.coolingPeriod = plan.coolingPeriod
                state.noteText = plan.note ?? ""
                state.coolingPeriodOverride = true
                state.editorErrorMessageKey = nil
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
                if state.coolingPeriodOverride == false,
                   let amount = CoolingOffAmountParser.parse(text), amount > 0 {
                    state.coolingPeriod = state.policy.suggestedPeriod(for: amount)
                }
                return .none

            case let .categoryChanged(category):
                state.category = category
                state.editorErrorMessageKey = nil
                return .none

            case let .coolingPeriodChanged(period):
                state.coolingPeriod = period
                state.coolingPeriodOverride = true
                return .none

            case let .noteTextChanged(text):
                state.noteText = text
                return .none

            case .useSuggestedPeriodTapped:
                state.coolingPeriodOverride = false
                if let amount = CoolingOffAmountParser.parse(state.amountText), amount > 0 {
                    state.coolingPeriod = state.policy.suggestedPeriod(for: amount)
                }
                return .none

            case .saveButtonTapped:
                guard let amount = CoolingOffAmountParser.parse(state.amountText), amount > 0 else {
                    state.editorErrorMessageKey = "coolingOff.error.amountMustBePositive"
                    return .none
                }
                let draft = PurchasePlanDraft(
                    title: state.titleText,
                    amount: amount,
                    category: state.category,
                    coolingPeriod: state.coolingPeriod,
                    note: state.noteText
                )
                do {
                    let plan: PurchasePlan = try {
                        if let id = state.editingPlanID, let existing = state.plans[id: id] {
                            return try draft.updating(existing: existing, now: date.now)
                        } else {
                            return try draft.validated(id: uuid(), now: date.now)
                        }
                    }()
                    state.isEditorPresented = false
                    return .run { send in
                        do {
                            try await repository.save(plan)
                            await send(.planSaved(plan))
                        } catch {
                            await send(.planSaveFailed("coolingOff.error.saveFailed"))
                        }
                    }
                } catch let error as PurchasePlanValidationError {
                    state.editorErrorMessageKey = error.messageKey
                    return .none
                } catch {
                    state.editorErrorMessageKey = "coolingOff.error.saveFailed"
                    return .none
                }

            case let .planSaved(plan):
                state.plans.remove(id: plan.id)
                state.plans.append(plan)
                return .none

            case let .planSaveFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case let .approveTapped(id):
                guard var plan = state.plans[id: id] else {
                    return .none
                }
                plan.status = .approved
                plan.decisionAt = date.now
                return saveExistingEffect(plan: plan, state: &state)

            case let .cancelTapped(id):
                guard var plan = state.plans[id: id] else {
                    return .none
                }
                plan.status = .cancelled
                plan.decisionAt = date.now
                return saveExistingEffect(plan: plan, state: &state)

            case let .deleteTapped(id):
                return .run { send in
                    do {
                        try await repository.delete(id)
                        await send(.planDeleted(id))
                    } catch {
                        await send(.planDeleteFailed("coolingOff.error.deleteFailed"))
                    }
                }

            case let .planDeleted(id):
                state.plans.remove(id: id)
                return .none

            case let .planDeleteFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveExistingEffect(plan: PurchasePlan, state: inout State) -> Effect<Action> {
        state.plans[id: plan.id] = plan
        return .run { send in
            do {
                try await repository.save(plan)
                await send(.planSaved(plan))
            } catch {
                await send(.planSaveFailed("coolingOff.error.saveFailed"))
            }
        }
    }
}

public enum CoolingOffAmountParser {
    public static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return nil
        }
        return Decimal(string: cleaned)
    }
}
