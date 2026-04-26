import ComposableArchitecture
import Foundation
import OnboardingDomain
import TransactionDomain

@Reducer
public struct OnboardingFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public static let availableCategories = TransactionCategory.defaultExpenseCategories

        public var profile: OnboardingProfile?
        public var step: Step
        public var monthlyIncomeText: String
        public var selectedCategoryIDs: Set<String>
        public var selectedGoal: FinancialGoal
        public var monthlySavingsTarget: Decimal
        public var suggestedBudgets: IdentifiedArrayOf<BudgetSuggestion>
        public var isLoading: Bool
        public var isSaving: Bool
        public var errorMessageKey: String?
        public var formErrorMessageKey: String?

        public init(
            profile: OnboardingProfile? = nil,
            step: Step = .income,
            monthlyIncomeText: String = "",
            selectedCategoryIDs: Set<String> = [
                TransactionCategory.food.id,
                TransactionCategory.transport.id,
                TransactionCategory.housing.id,
            ],
            selectedGoal: FinancialGoal = .buildEmergencyFund,
            monthlySavingsTarget: Decimal = 0,
            suggestedBudgets: IdentifiedArrayOf<BudgetSuggestion> = [],
            isLoading: Bool = false,
            isSaving: Bool = false,
            errorMessageKey: String? = nil,
            formErrorMessageKey: String? = nil
        ) {
            self.profile = profile
            self.step = step
            self.monthlyIncomeText = monthlyIncomeText
            self.selectedCategoryIDs = selectedCategoryIDs
            self.selectedGoal = selectedGoal
            self.monthlySavingsTarget = monthlySavingsTarget
            self.suggestedBudgets = suggestedBudgets
            self.isLoading = isLoading
            self.isSaving = isSaving
            self.errorMessageKey = errorMessageKey
            self.formErrorMessageKey = formErrorMessageKey
        }

        public var selectedCategories: [TransactionCategory] {
            Self.availableCategories.filter {
                selectedCategoryIDs.contains($0.id)
            }
        }
    }

    public enum Step: Int, CaseIterable, Equatable, Identifiable, Sendable {
        case income
        case categories
        case goal
        case review

        public var id: Int {
            rawValue
        }

        public var progress: Double {
            Double(rawValue + 1) / Double(Self.allCases.count)
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case profileLoaded(OnboardingProfile?)
        case loadFailed(String)
        case monthlyIncomeTextChanged(String)
        case categoryTapped(String)
        case goalSelected(FinancialGoal)
        case nextButtonTapped
        case backButtonTapped
        case completeButtonTapped
        case profileSaved(OnboardingProfile)
        case saveFailed(String)
    }

    @Dependency(\.date.now) private var now
    @Dependency(\.onboardingProfileRepository) private var repository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let profile = try await repository.load()
                        await send(.profileLoaded(profile))
                    } catch {
                        await send(.loadFailed("onboarding.error.loadFailed"))
                    }
                }

            case let .profileLoaded(profile):
                state.isLoading = false
                state.profile = profile
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .monthlyIncomeTextChanged(monthlyIncomeText):
                state.monthlyIncomeText = monthlyIncomeText
                state.formErrorMessageKey = nil
                return .none

            case let .categoryTapped(categoryID):
                guard State.availableCategories.contains(where: { $0.id == categoryID }) else {
                    return .none
                }

                if state.selectedCategoryIDs.contains(categoryID) {
                    state.selectedCategoryIDs.remove(categoryID)
                } else {
                    state.selectedCategoryIDs.insert(categoryID)
                }
                state.formErrorMessageKey = nil
                return .none

            case let .goalSelected(goal):
                state.selectedGoal = goal
                state.formErrorMessageKey = nil
                return .none

            case .nextButtonTapped:
                return next(state: &state)

            case .backButtonTapped:
                state.formErrorMessageKey = nil
                switch state.step {
                case .income:
                    return .none
                case .categories:
                    state.step = .income
                case .goal:
                    state.step = .categories
                case .review:
                    state.step = .goal
                }
                return .none

            case .completeButtonTapped:
                return saveProfile(state: &state)

            case let .profileSaved(profile):
                state.isSaving = false
                state.profile = profile
                state.errorMessageKey = nil
                return .none

            case let .saveFailed(messageKey):
                state.isSaving = false
                state.errorMessageKey = messageKey
                state.formErrorMessageKey = messageKey
                return .none
            }
        }
    }

    private func next(state: inout State) -> Effect<Action> {
        state.formErrorMessageKey = nil

        switch state.step {
        case .income:
            guard parsedIncome(from: state) != nil else {
                state.formErrorMessageKey = "onboarding.error.invalidIncome"
                return .none
            }
            state.step = .categories
            return .none

        case .categories:
            guard state.selectedCategories.isEmpty == false else {
                state.formErrorMessageKey = "onboarding.error.categoriesRequired"
                return .none
            }
            state.step = .goal
            return .none

        case .goal:
            guard let profile = makeProfile(from: &state, completedAt: now) else {
                return .none
            }
            state.monthlySavingsTarget = profile.monthlySavingsTarget
            state.suggestedBudgets = IdentifiedArray(
                uniqueElements: profile.suggestedBudgets
            )
            state.step = .review
            return .none

        case .review:
            return saveProfile(state: &state)
        }
    }

    private func saveProfile(state: inout State) -> Effect<Action> {
        guard let profile = makeProfile(from: &state, completedAt: now) else {
            return .none
        }

        state.suggestedBudgets = IdentifiedArray(
            uniqueElements: profile.suggestedBudgets
        )
        state.monthlySavingsTarget = profile.monthlySavingsTarget
        state.isSaving = true
        state.errorMessageKey = nil
        state.formErrorMessageKey = nil

        return .run { send in
            do {
                try await repository.save(profile)
                await send(.profileSaved(profile))
            } catch {
                await send(.saveFailed("onboarding.error.saveFailed"))
            }
        }
    }

    private func makeProfile(
        from state: inout State,
        completedAt: Date
    ) -> OnboardingProfile? {
        guard let monthlyIncome = parsedIncome(from: state) else {
            state.formErrorMessageKey = "onboarding.error.invalidIncome"
            return nil
        }

        do {
            return try OnboardingPlanner.makeProfile(
                monthlyIncome: monthlyIncome,
                primaryCategories: state.selectedCategories,
                financialGoal: state.selectedGoal,
                completedAt: completedAt
            )
        } catch OnboardingValidationError.monthlyIncomeMustBePositive {
            state.formErrorMessageKey = "onboarding.error.invalidIncome"
            return nil
        } catch OnboardingValidationError.primaryCategoriesRequired {
            state.formErrorMessageKey = "onboarding.error.categoriesRequired"
            return nil
        } catch {
            state.formErrorMessageKey = "onboarding.error.saveFailed"
            return nil
        }
    }

    private func parsedIncome(from state: State) -> Decimal? {
        guard
            let monthlyIncome = TransactionAmountParser.parse(state.monthlyIncomeText),
            monthlyIncome > Decimal(0)
        else {
            return nil
        }

        return monthlyIncome
    }
}
