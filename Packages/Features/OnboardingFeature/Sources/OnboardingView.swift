import ComposableArchitecture
import KasoDesignSystem
import OnboardingDomain
import SwiftUI
import TransactionDomain

public struct OnboardingRootView: View {
    private let store: StoreOf<OnboardingFeature>

    public init(repository: OnboardingProfileRepository = .empty) {
        store = Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        } withDependencies: {
            $0.onboardingProfileRepository = repository
        }
    }

    public var body: some View {
        OnboardingView(store: store)
    }
}

public struct OnboardingView: View {
    @Bindable private var store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if store.isLoading {
                    Spacer()
                    ProgressView()
                        .accessibilityLabel(Text("onboarding.loading", bundle: .module))
                    Spacer()
                } else {
                    progressHeader
                    stepContent
                    Spacer(minLength: Spacing.lg)
                    footer
                }
            }
            .padding(Spacing.lg)
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("onboarding.navigation.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ProgressView(value: store.step.progress)
                .tint(Color.kaso.accent)

            Text(progressTitleKey)
                .font(.kaso.titleLarge)
                .foregroundStyle(Color.kaso.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(progressSubtitleKey)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch store.step {
        case .income:
            IncomeStep(
                monthlyIncomeText: monthlyIncomeBinding,
                formErrorMessageKey: store.formErrorMessageKey
            )
        case .categories:
            CategoriesStep(
                selectedCategoryIDs: store.selectedCategoryIDs,
                formErrorMessageKey: store.formErrorMessageKey,
                onCategoryTapped: { categoryID in
                    store.send(.categoryTapped(categoryID))
                }
            )
        case .goal:
            GoalStep(
                selectedGoal: store.selectedGoal,
                onGoalSelected: { goal in
                    store.send(.goalSelected(goal))
                }
            )
        case .review:
            ReviewStep(
                suggestedBudgets: Array(store.suggestedBudgets),
                monthlySavingsTarget: store.monthlySavingsTarget,
                formErrorMessageKey: store.formErrorMessageKey
            )
        }
    }

    private var footer: some View {
        VStack(spacing: Spacing.md) {
            if let errorMessageKey = store.errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Spacing.md) {
                if store.step != .income {
                    Button {
                        store.send(.backButtonTapped)
                    } label: {
                        Text("onboarding.back", bundle: .module)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.isSaving)
                }

                Button {
                    if store.step == .review {
                        store.send(.completeButtonTapped)
                    } else {
                        store.send(.nextButtonTapped)
                    }
                } label: {
                    if store.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(primaryButtonKey, bundle: .module)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isSaving)
            }
        }
    }

    private var monthlyIncomeBinding: Binding<String> {
        Binding(
            get: { store.monthlyIncomeText },
            set: { store.send(.monthlyIncomeTextChanged($0)) }
        )
    }

    private var progressTitleKey: LocalizedStringKey {
        switch store.step {
        case .income:
            "onboarding.income.title"
        case .categories:
            "onboarding.categories.title"
        case .goal:
            "onboarding.goal.title"
        case .review:
            "onboarding.review.title"
        }
    }

    private var progressSubtitleKey: LocalizedStringKey {
        switch store.step {
        case .income:
            "onboarding.income.subtitle"
        case .categories:
            "onboarding.categories.subtitle"
        case .goal:
            "onboarding.goal.subtitle"
        case .review:
            "onboarding.review.subtitle"
        }
    }

    private var primaryButtonKey: LocalizedStringKey {
        store.step == .review ? "onboarding.complete" : "onboarding.next"
    }
}

private struct IncomeStep: View {
    @Binding var monthlyIncomeText: String
    let formErrorMessageKey: String?

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("onboarding.income.field", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                TextField(
                    text: $monthlyIncomeText,
                    prompt: Text("onboarding.income.placeholder", bundle: .module)
                ) {
                    Text("onboarding.income.field", bundle: .module)
                }
                .font(.kaso.numericLarge)
                .kasoDecimalKeyboard()

                if let formErrorMessageKey {
                    Text(LocalizedStringKey(formErrorMessageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }
            }
        }
    }
}

private struct CategoriesStep: View {
    let selectedCategoryIDs: Set<String>
    let formErrorMessageKey: String?
    let onCategoryTapped: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: Spacing.xl * 4), spacing: Spacing.sm),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(OnboardingFeature.State.availableCategories) { category in
                    CategoryToggleCard(
                        category: category,
                        isSelected: selectedCategoryIDs.contains(category.id),
                        action: {
                            onCategoryTapped(category.id)
                        }
                    )
                }
            }

            if let formErrorMessageKey {
                Text(LocalizedStringKey(formErrorMessageKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
            }
        }
    }
}

private struct CategoryToggleCard: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: category.symbolName)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(isSelected ? Color.kaso.accent : Color.kaso.textSecondary)

                Text(LocalizedStringKey(category.nameKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .background(
                Color.kaso.surfaceSecondary,
                in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(
                        isSelected ? Color.kaso.accent : Color.kaso.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct GoalStep: View {
    let selectedGoal: FinancialGoal
    let onGoalSelected: (FinancialGoal) -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(FinancialGoal.allCases) { goal in
                GoalOptionCard(
                    goal: goal,
                    isSelected: selectedGoal == goal,
                    action: {
                        onGoalSelected(goal)
                    }
                )
            }
        }
    }
}

private struct GoalOptionCard: View {
    let goal: FinancialGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: goal.symbolName)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(isSelected ? Color.kaso.accent : Color.kaso.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(goal.nameKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text(LocalizedStringKey(goal.descriptionKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.sm)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .background(
                Color.kaso.surfaceSecondary,
                in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(
                        isSelected ? Color.kaso.accent : Color.kaso.surfaceSecondary,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ReviewStep: View {
    let suggestedBudgets: [BudgetSuggestion]
    let monthlySavingsTarget: Decimal
    let formErrorMessageKey: String?

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("onboarding.review.budgetPlan", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                VStack(spacing: Spacing.sm) {
                    ForEach(suggestedBudgets) { suggestion in
                        SuggestedBudgetRow(suggestion: suggestion)
                    }
                }

                Divider()

                HStack {
                    Text("onboarding.review.savingsTarget", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)

                    Spacer(minLength: Spacing.md)

                    Text(monthlySavingsTarget.formatted(.currency(code: "VND")))
                        .font(.kaso.numericMedium)
                        .foregroundStyle(Color.kaso.accent)
                }

                if let formErrorMessageKey {
                    Text(LocalizedStringKey(formErrorMessageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                }
            }
        }
    }
}

private struct SuggestedBudgetRow: View {
    let suggestion: BudgetSuggestion

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: suggestion.category.symbolName)
                .foregroundStyle(Color.kaso.accent)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(suggestion.category.nameKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Spacer(minLength: Spacing.md)

            Text(suggestion.monthlyLimit.formatted(.currency(code: "VND")))
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private extension View {
    @ViewBuilder
    func kasoDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }
}

#Preview("Light") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}

#Preview("Dark") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
