import BudgetDomain
import ComposableArchitecture
import Foundation
import GamificationDomain
import TransactionDomain

@Reducer
public struct GamificationFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var profile: GamificationProfile
        public var transactions: [Transaction]
        public var budgets: [Budget]
        public var referenceDate: Date
        public var isLoading: Bool
        public var newlyEarnedEvents: [RewardEvent]
        public var celebratingMilestone: RewardEventKind?
        public var achievementProgresses: [AchievementProgress]
        public var newlyUnlockedAchievements: [AchievementKind]
        public var celebratingAchievement: AchievementKind?
        public var financialLevelProgress: FinancialLevelProgress
        public var celebratingFinancialLevel: FinancialLevel?
        public var celebratingWeeklyChallenge: WeeklyChallenge?
        public var errorMessageKey: String?

        public init(
            profile: GamificationProfile = GamificationProfile(),
            transactions: [Transaction] = [],
            budgets: [Budget] = [],
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            isLoading: Bool = false,
            newlyEarnedEvents: [RewardEvent] = [],
            celebratingMilestone: RewardEventKind? = nil,
            achievementProgresses: [AchievementProgress] = [],
            newlyUnlockedAchievements: [AchievementKind] = [],
            celebratingAchievement: AchievementKind? = nil,
            financialLevelProgress: FinancialLevelProgress = FinancialLevelProgress(totalPoints: 0),
            celebratingFinancialLevel: FinancialLevel? = nil,
            celebratingWeeklyChallenge: WeeklyChallenge? = nil,
            errorMessageKey: String? = nil
        ) {
            self.profile = profile
            self.transactions = transactions
            self.budgets = budgets
            self.referenceDate = referenceDate
            self.isLoading = isLoading
            self.newlyEarnedEvents = newlyEarnedEvents
            self.celebratingMilestone = celebratingMilestone
            self.achievementProgresses = achievementProgresses
            self.newlyUnlockedAchievements = newlyUnlockedAchievements
            self.celebratingAchievement = celebratingAchievement
            self.financialLevelProgress = financialLevelProgress
            self.celebratingFinancialLevel = celebratingFinancialLevel
            self.celebratingWeeklyChallenge = celebratingWeeklyChallenge
            self.errorMessageKey = errorMessageKey
        }

        public var todaysEarnedPoints: Int {
            newlyEarnedEvents.reduce(0) { $0 + $1.points }
        }

        public var unlockedAchievementCount: Int {
            achievementProgresses.filter(\.isUnlocked).count
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case dataLoaded(GamificationProfile?, [Transaction], [Budget])
        case loadFailed(String)
        case profilePersisted
        case persistFailed(String)
        case celebrationDismissed
        case achievementCelebrationDismissed
        case financialLevelCelebrationDismissed
        case weeklyChallengeCelebrationDismissed
    }

    @Dependency(\.gamificationProfileRepository) private var repository
    @Dependency(\.gamificationContextClient) private var contextClient
    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                state.referenceDate = date.now
                return .run { send in
                    do {
                        async let profile = repository.load()
                        async let transactions = contextClient.loadTransactions()
                        async let budgets = contextClient.loadBudgets()
                        let loaded = try await (profile, transactions, budgets)
                        await send(.dataLoaded(loaded.0, loaded.1, loaded.2))
                    } catch {
                        await send(.loadFailed("gamification.error.loadFailed"))
                    }
                }

            case let .dataLoaded(profile, transactions, budgets):
                state.isLoading = false
                state.transactions = transactions
                state.budgets = budgets

                let evaluation = GamificationCalculator.evaluate(
                    profile: profile ?? GamificationProfile(),
                    transactions: transactions,
                    budgets: budgets,
                    referenceDate: state.referenceDate
                )

                state.profile = evaluation.profile
                state.newlyEarnedEvents = evaluation.newEvents
                state.celebratingMilestone = evaluation.achievedMilestone
                state.achievementProgresses = evaluation.achievementProgresses
                state.newlyUnlockedAchievements = evaluation.newlyUnlockedAchievements
                state.celebratingAchievement = evaluation.newlyUnlockedAchievements.first
                state.financialLevelProgress = evaluation.financialLevelProgress
                state.celebratingFinancialLevel = evaluation.newlyAchievedFinancialLevel
                state.celebratingWeeklyChallenge = evaluation.newlyCompletedWeeklyChallenge

                let evaluatedProfile = evaluation.profile
                return .run { send in
                    do {
                        try await repository.save(evaluatedProfile)
                        await send(.profilePersisted)
                    } catch {
                        await send(.persistFailed("gamification.error.saveFailed"))
                    }
                }

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .profilePersisted:
                return .none

            case let .persistFailed(messageKey):
                state.errorMessageKey = messageKey
                return .none

            case .celebrationDismissed:
                state.celebratingMilestone = nil
                return .none

            case .achievementCelebrationDismissed:
                guard let dismissed = state.celebratingAchievement else {
                    return .none
                }
                state.newlyUnlockedAchievements.removeAll { $0 == dismissed }
                state.celebratingAchievement = state.newlyUnlockedAchievements.first
                return .none

            case .financialLevelCelebrationDismissed:
                state.celebratingFinancialLevel = nil
                return .none

            case .weeklyChallengeCelebrationDismissed:
                state.celebratingWeeklyChallenge = nil
                return .none
            }
        }
    }
}
