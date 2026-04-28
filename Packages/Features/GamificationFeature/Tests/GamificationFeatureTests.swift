import BudgetDomain
import ComposableArchitecture
import Foundation
import GamificationDomain
import Testing
import TransactionDomain
@testable import GamificationFeature

@MainActor
@Test("task evaluates streak from loaded data and persists profile")
func taskEvaluatesStreakAndPersistsProfile() async throws {
    let referenceDate = try makeDate(2026, 4, 26)
    let transactions = [
        Transaction(
            amount: 50_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let savedBox = SendableBox<GamificationProfile?>(nil)

    let store = TestStore(initialState: GamificationFeature.State()) {
        GamificationFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.gamificationProfileRepository = GamificationProfileRepository(
            load: { nil },
            save: { profile in
                await savedBox.set(profile)
            },
            clear: {}
        )
        $0.gamificationContextClient = GamificationContextClient(
            loadTransactions: { transactions },
            loadBudgets: { [] }
        )
    }
    store.exhaustivity = .off

    await store.send(.task)
    await store.receive(\.dataLoaded)
    await store.receive(\.profilePersisted)

    #expect(store.state.isLoading == false)
    #expect(store.state.profile.currentStreak == 1)
    #expect(store.state.profile.totalPoints == RewardEventKind.dailyEntry.points)
    #expect(store.state.newlyEarnedEvents.contains { $0.kind == .dailyEntry })
    #expect(store.state.profile.unlockedAchievements.contains(.firstSteps))
    #expect(store.state.celebratingAchievement == .firstSteps)
    #expect(store.state.achievementProgresses.isEmpty == false)

    let saved = await savedBox.value
    #expect(saved?.currentStreak == 1)
    #expect(saved?.unlockedAchievements.contains(.firstSteps) == true)
    #expect(saved?.lastNotifiedFinancialLevel == .sprout)
    #expect(store.state.financialLevelProgress.level == .sprout)
    #expect(store.state.celebratingFinancialLevel == nil)
}

@MainActor
@Test("weekly challenge celebration dismiss clears state")
func weeklyChallengeCelebrationDismiss() async throws {
    let referenceDate = try makeDate(2026, 4, 27)
    let challenge = WeeklyChallenge(
        kind: .categoryVariety,
        weekStart: referenceDate,
        currentProgress: 4,
        completedAt: referenceDate
    )
    let store = TestStore(
        initialState: GamificationFeature.State(
            celebratingWeeklyChallenge: challenge
        )
    ) {
        GamificationFeature()
    }

    await store.send(.weeklyChallengeCelebrationDismissed) {
        $0.celebratingWeeklyChallenge = nil
    }
}

@MainActor
@Test("loading without active challenge generates one through evaluation")
func loadingGeneratesWeeklyChallenge() async throws {
    let referenceDate = try makeDate(2026, 4, 27)
    let store = TestStore(initialState: GamificationFeature.State()) {
        GamificationFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.gamificationProfileRepository = GamificationProfileRepository(
            load: { nil },
            save: { _ in },
            clear: {}
        )
        $0.gamificationContextClient = GamificationContextClient(
            loadTransactions: { [] },
            loadBudgets: { [] }
        )
    }
    store.exhaustivity = .off

    await store.send(.task)
    await store.receive(\.dataLoaded)
    await store.receive(\.profilePersisted)

    #expect(store.state.profile.activeWeeklyChallenge != nil)
    #expect(store.state.celebratingWeeklyChallenge == nil)
}

@MainActor
@Test("financial level upgrade is celebrated and dismissable")
func financialLevelUpgradeCelebrated() async throws {
    let referenceDate = try makeDate(2026, 4, 26)
    let transactions = [
        Transaction(
            amount: 50_000,
            kind: .expense,
            category: .food,
            occurredAt: referenceDate
        ),
    ]
    let priorProfile = GamificationProfile(
        currentStreak: 1,
        longestStreak: 1,
        totalPoints: 195,
        lastActivityDate: referenceDate.addingTimeInterval(-3_600 * 24),
        lastEvaluatedDate: referenceDate.addingTimeInterval(-3_600 * 24),
        lastNotifiedFinancialLevel: .sprout
    )

    let store = TestStore(initialState: GamificationFeature.State()) {
        GamificationFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.gamificationProfileRepository = GamificationProfileRepository(
            load: { priorProfile },
            save: { _ in },
            clear: {}
        )
        $0.gamificationContextClient = GamificationContextClient(
            loadTransactions: { transactions },
            loadBudgets: { [] }
        )
    }
    store.exhaustivity = .off

    await store.send(.task)
    await store.receive(\.dataLoaded)
    await store.receive(\.profilePersisted)

    #expect(store.state.celebratingFinancialLevel == .bronze)
    #expect(store.state.financialLevelProgress.level == .bronze)

    await store.send(.financialLevelCelebrationDismissed) {
        $0.celebratingFinancialLevel = nil
    }
}

@MainActor
@Test("celebration is dismissed by user action")
func celebrationDismissed() async throws {
    let store = TestStore(
        initialState: GamificationFeature.State(
            celebratingMilestone: .streakMilestone3
        )
    ) {
        GamificationFeature()
    }

    await store.send(.celebrationDismissed) {
        $0.celebratingMilestone = nil
    }
}

@MainActor
@Test("achievement celebration dismiss advances queue")
func achievementCelebrationDismissAdvancesQueue() async throws {
    let store = TestStore(
        initialState: GamificationFeature.State(
            newlyUnlockedAchievements: [.firstSteps, .earlyBird],
            celebratingAchievement: .firstSteps
        )
    ) {
        GamificationFeature()
    }

    await store.send(.achievementCelebrationDismissed) {
        $0.newlyUnlockedAchievements = [.earlyBird]
        $0.celebratingAchievement = .earlyBird
    }

    await store.send(.achievementCelebrationDismissed) {
        $0.newlyUnlockedAchievements = []
        $0.celebratingAchievement = nil
    }
}

@MainActor
@Test("achievement celebration dismiss is a no-op when nothing to dismiss")
func achievementCelebrationDismissNoOp() async throws {
    let store = TestStore(initialState: GamificationFeature.State()) {
        GamificationFeature()
    }

    await store.send(.achievementCelebrationDismissed)
}

@MainActor
@Test("loadFailed surfaces error message key")
func loadFailedSurfacesError() async throws {
    let store = TestStore(initialState: GamificationFeature.State(isLoading: true)) {
        GamificationFeature()
    }

    await store.send(.loadFailed("gamification.error.loadFailed")) {
        $0.isLoading = false
        $0.errorMessageKey = "gamification.error.loadFailed"
    }
}

@MainActor
@Test("persistFailed surfaces error message key")
func persistFailedSurfacesError() async throws {
    let store = TestStore(initialState: GamificationFeature.State()) {
        GamificationFeature()
    }

    await store.send(.persistFailed("gamification.error.saveFailed")) {
        $0.errorMessageKey = "gamification.error.saveFailed"
    }
}

@MainActor
@Test("unlocked achievement count counts only unlocked progresses")
func unlockedAchievementCountReturnsOnlyUnlocked() {
    let progresses: [AchievementProgress] = [
        AchievementProgress(kind: .firstSteps, currentValue: 1, isUnlocked: true),
        AchievementProgress(kind: .weekWarrior, currentValue: 2, isUnlocked: false),
        AchievementProgress(kind: .earlyBird, currentValue: 1, isUnlocked: true),
    ]
    let state = GamificationFeature.State(achievementProgresses: progresses)
    #expect(state.unlockedAchievementCount == 2)
}

private func makeDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int = 12
) throws -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    return try #require(Calendar(identifier: .gregorian).date(from: components))
}

private actor SendableBox<Value: Sendable> {
    private(set) var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func set(_ newValue: Value) {
        value = newValue
    }
}
