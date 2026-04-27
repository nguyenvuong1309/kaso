import Foundation
import ComposableArchitecture
import FreelancerDomain

@Reducer
public struct FreelancerFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var profile: FreelancerProfile?
        public var smoothedView: FreelancerSmoothedView?
        public var incomeHistory: [MonthlyIncome]
        public var reminders: [FreelancerReminder]
        public var selectedWindow: SmoothingWindow
        public var isLoading: Bool
        public var isIncomeEditorPresented: Bool
        public var isProfileEditorPresented: Bool
        public var isSavingIncome: Bool
        public var isSavingProfile: Bool
        public var incomeDate: Date
        public var incomeGrossText: String
        public var incomeDeductionText: String
        public var bufferBalanceText: String
        public var bufferTargetMonthsText: String
        public var taxRateText: String
        public var workType: FreelancerWorkType
        public var errorMessageKey: String?
        public var editorErrorMessageKey: String?

        public init(
            profile: FreelancerProfile? = nil,
            smoothedView: FreelancerSmoothedView? = nil,
            incomeHistory: [MonthlyIncome]? = nil,
            reminders: [FreelancerReminder] = [],
            selectedWindow: SmoothingWindow? = nil,
            isLoading: Bool = false,
            isIncomeEditorPresented: Bool = false,
            isProfileEditorPresented: Bool = false,
            isSavingIncome: Bool = false,
            isSavingProfile: Bool = false,
            incomeDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            incomeGrossText: String = "",
            incomeDeductionText: String = "",
            bufferBalanceText: String = "",
            bufferTargetMonthsText: String = "2",
            taxRateText: String = "",
            workType: FreelancerWorkType = .freelancer,
            errorMessageKey: String? = nil,
            editorErrorMessageKey: String? = nil
        ) {
            self.profile = profile
            self.smoothedView = smoothedView
            self.incomeHistory = incomeHistory ?? profile?.monthlyIncomes ?? []
            self.reminders = reminders
            self.selectedWindow = selectedWindow ?? profile?.smoothingWindow ?? .threeMonths
            self.isLoading = isLoading
            self.isIncomeEditorPresented = isIncomeEditorPresented
            self.isProfileEditorPresented = isProfileEditorPresented
            self.isSavingIncome = isSavingIncome
            self.isSavingProfile = isSavingProfile
            self.incomeDate = incomeDate
            self.incomeGrossText = incomeGrossText
            self.incomeDeductionText = incomeDeductionText
            self.bufferBalanceText = bufferBalanceText
            self.bufferTargetMonthsText = bufferTargetMonthsText
            self.taxRateText = taxRateText
            self.workType = workType
            self.errorMessageKey = errorMessageKey
            self.editorErrorMessageKey = editorErrorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case profileLoaded(FreelancerProfile?)
        case loadFailed(String)
        case smoothingWindowChanged(SmoothingWindow)
        case addIncomeButtonTapped
        case incomeEditorDismissed
        case incomeDateChanged(Date)
        case incomeGrossTextChanged(String)
        case incomeDeductionTextChanged(String)
        case saveIncomeButtonTapped
        case incomeSaved(FreelancerProfile)
        case saveIncomeFailed(String)
        case profileButtonTapped
        case profileEditorDismissed
        case bufferBalanceTextChanged(String)
        case bufferTargetMonthsTextChanged(String)
        case taxRateTextChanged(String)
        case workTypeChanged(FreelancerWorkType)
        case saveProfileButtonTapped
        case profileSaved(FreelancerProfile)
        case saveProfileFailed(String)
    }

    @Dependency(\.freelancerProfileRepository) private var repository
    @Dependency(\.date) private var date
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
                        await send(.profileLoaded(try await repository.load()))
                    } catch {
                        await send(.loadFailed("freelancer.error.loadFailed"))
                    }
                }

            case let .profileLoaded(profile):
                state.isLoading = false
                apply(profile: profile, to: &state)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .smoothingWindowChanged(window):
                state.selectedWindow = window
                state.profile?.smoothingWindow = window
                recompute(&state)
                return .none

            case .addIncomeButtonTapped:
                state.incomeDate = date.now
                state.incomeGrossText = ""
                state.incomeDeductionText = ""
                state.editorErrorMessageKey = nil
                state.isIncomeEditorPresented = true
                return .none

            case .incomeEditorDismissed:
                state.isIncomeEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .incomeDateChanged(incomeDate):
                state.incomeDate = incomeDate
                return .none

            case let .incomeGrossTextChanged(text):
                state.incomeGrossText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .incomeDeductionTextChanged(text):
                state.incomeDeductionText = text
                state.editorErrorMessageKey = nil
                return .none

            case .saveIncomeButtonTapped:
                return saveIncomeEffect(&state)

            case let .incomeSaved(profile):
                state.isSavingIncome = false
                state.isIncomeEditorPresented = false
                state.incomeGrossText = ""
                state.incomeDeductionText = ""
                apply(profile: profile, to: &state)
                return .none

            case let .saveIncomeFailed(messageKey):
                state.isSavingIncome = false
                state.editorErrorMessageKey = messageKey
                return .none

            case .profileButtonTapped:
                populateProfileFields(&state)
                state.editorErrorMessageKey = nil
                state.isProfileEditorPresented = true
                return .none

            case .profileEditorDismissed:
                state.isProfileEditorPresented = false
                state.editorErrorMessageKey = nil
                return .none

            case let .bufferBalanceTextChanged(text):
                state.bufferBalanceText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .bufferTargetMonthsTextChanged(text):
                state.bufferTargetMonthsText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .taxRateTextChanged(text):
                state.taxRateText = text
                state.editorErrorMessageKey = nil
                return .none

            case let .workTypeChanged(workType):
                state.workType = workType
                return .none

            case .saveProfileButtonTapped:
                return saveProfileEffect(&state)

            case let .profileSaved(profile):
                state.isSavingProfile = false
                state.isProfileEditorPresented = false
                apply(profile: profile, to: &state)
                return .none

            case let .saveProfileFailed(messageKey):
                state.isSavingProfile = false
                state.editorErrorMessageKey = messageKey
                return .none
            }
        }
    }

    private func saveIncomeEffect(_ state: inout State) -> Effect<Action> {
        guard let grossAmount = FreelancerFeatureFormatters.parseDecimal(state.incomeGrossText), grossAmount > 0 else {
            state.editorErrorMessageKey = "freelancer.error.invalidIncome"
            return .none
        }

        let deductionAmount = FreelancerFeatureFormatters.parseDecimal(state.incomeDeductionText) ?? 0
        let deductions = deductionAmount > 0
            ? [IncomeDeduction(id: uuid(), title: "Business costs", amount: deductionAmount, category: .businessCost)]
            : []
        var profile = state.profile ?? makeDefaultProfile(from: state)
        let income = MonthlyIncome(
            month: YearMonth(date: state.incomeDate),
            grossAmount: grossAmount,
            deductions: deductions
        )
        profile.monthlyIncomes.removeAll { $0.month == income.month }
        profile.monthlyIncomes.append(income)
        profile.monthlyIncomes.sort { $0.month < $1.month }
        profile.updatedAt = date.now
        let profileToSave = profile
        state.isSavingIncome = true

        return .run { send in
            do {
                try await repository.save(profileToSave)
                await send(.incomeSaved(profileToSave))
            } catch {
                await send(.saveIncomeFailed("freelancer.error.saveFailed"))
            }
        }
    }

    private func saveProfileEffect(_ state: inout State) -> Effect<Action> {
        guard let bufferBalance = FreelancerFeatureFormatters.parseDecimal(state.bufferBalanceText) else {
            state.editorErrorMessageKey = "freelancer.error.invalidBuffer"
            return .none
        }
        guard let targetMonths = FreelancerFeatureFormatters.parseDouble(state.bufferTargetMonthsText), targetMonths > 0 else {
            state.editorErrorMessageKey = "freelancer.error.invalidTarget"
            return .none
        }

        let taxRate: Double?
        if state.taxRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            taxRate = nil
        } else if let percent = FreelancerFeatureFormatters.parseDouble(state.taxRateText), percent >= 0 {
            taxRate = percent / 100
        } else {
            state.editorErrorMessageKey = "freelancer.error.invalidTax"
            return .none
        }

        var profile = state.profile ?? makeDefaultProfile(from: state)
        profile.smoothingWindow = state.selectedWindow
        profile.bufferBalance = bufferBalance
        profile.bufferTargetMultiplier = targetMonths
        profile.taxRate = taxRate
        profile.workType = state.workType
        profile.updatedAt = date.now
        let profileToSave = profile
        state.isSavingProfile = true

        return .run { send in
            do {
                try await repository.save(profileToSave)
                await send(.profileSaved(profileToSave))
            } catch {
                await send(.saveProfileFailed("freelancer.error.saveFailed"))
            }
        }
    }

    private func makeDefaultProfile(from state: State) -> FreelancerProfile {
        FreelancerProfile(
            id: uuid(),
            monthlyIncomes: state.incomeHistory,
            smoothingWindow: state.selectedWindow,
            bufferBalance: FreelancerFeatureFormatters.parseDecimal(state.bufferBalanceText) ?? 0,
            bufferTargetMultiplier: FreelancerFeatureFormatters.parseDouble(state.bufferTargetMonthsText) ?? 2,
            workType: state.workType,
            taxRate: FreelancerFeatureFormatters.parseDouble(state.taxRateText).map { $0 / 100 },
            createdAt: date.now,
            updatedAt: date.now
        )
    }

    private func apply(profile: FreelancerProfile?, to state: inout State) {
        state.profile = profile
        state.incomeHistory = profile?.monthlyIncomes ?? []
        if let profile {
            state.selectedWindow = profile.smoothingWindow
            populateProfileFields(&state)
            recompute(&state)
        } else {
            state.smoothedView = nil
            state.reminders = []
        }
    }

    private func populateProfileFields(_ state: inout State) {
        guard let profile = state.profile else {
            return
        }
        state.bufferBalanceText = FreelancerFeatureFormatters.amountText(profile.bufferBalance)
        state.bufferTargetMonthsText = NSDecimalNumber(value: profile.bufferTargetMultiplier).stringValue
        state.taxRateText = FreelancerFeatureFormatters.percentText(profile.taxRate)
        state.workType = profile.workType
    }

    private func recompute(_ state: inout State) {
        guard let profile = state.profile else {
            return
        }
        let view = FreelancerIncomeSmoother.compute(
            profile: profile,
            window: state.selectedWindow,
            asOf: date.now
        )
        state.smoothedView = view
        state.reminders = FreelancerIncomeSmoother.reminders(
            for: profile,
            view: view,
            asOf: date.now
        )
    }
}
