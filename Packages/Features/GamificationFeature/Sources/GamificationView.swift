import ComposableArchitecture
import GamificationDomain
import KasoDesignSystem
import SwiftUI

public struct GamificationView: View {
    @Bindable private var store: StoreOf<GamificationFeature>

    public init(store: StoreOf<GamificationFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if let messageKey = store.errorMessageKey {
                        GamificationErrorLabel(messageKey: messageKey)
                    }

                    KasoCard {
                        GamificationFinancialLevelCard(progress: store.financialLevelProgress)
                    }

                    KasoCard {
                        GamificationWeeklyChallengeCard(
                            challenge: store.profile.activeWeeklyChallenge,
                            referenceDate: store.referenceDate
                        )
                    }

                    KasoCard {
                        GamificationStreakCard(profile: store.profile)
                    }

                    KasoCard {
                        GamificationPointsCard(
                            profile: store.profile,
                            earnedToday: store.todaysEarnedPoints
                        )
                    }

                    KasoCard {
                        GamificationMilestonesCard(
                            unlocked: store.profile.unlockedMilestones
                        )
                    }

                    KasoCard {
                        GamificationAchievementsCard(
                            progresses: store.achievementProgresses,
                            unlockedCount: store.unlockedAchievementCount
                        )
                    }

                    KasoCard {
                        GamificationRewardsCard(events: store.profile.rewardEvents)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("gamification.title", bundle: .module))
            .task {
                await store.send(.task).finish()
            }
            .alert(
                Text(
                    "gamification.financialLevel.celebrationTitle",
                    bundle: .module
                ),
                isPresented: financialLevelCelebrationPresented,
                presenting: store.celebratingFinancialLevel
            ) { _ in
                Button {
                    store.send(.financialLevelCelebrationDismissed)
                } label: {
                    Text("gamification.financialLevel.celebrationDismiss", bundle: .module)
                }
            } message: { level in
                let name = NSLocalizedString(level.nameKey, bundle: .module, comment: "")
                Text(
                    "gamification.financialLevel.celebrationMessage \(name)",
                    bundle: .module
                )
            }
            .alert(
                Text(
                    "gamification.weeklyChallenge.celebrationTitle",
                    bundle: .module
                ),
                isPresented: weeklyChallengeCelebrationPresented,
                presenting: store.celebratingWeeklyChallenge
            ) { _ in
                Button {
                    store.send(.weeklyChallengeCelebrationDismissed)
                } label: {
                    Text("gamification.weeklyChallenge.celebrationDismiss", bundle: .module)
                }
            } message: { challenge in
                let name = NSLocalizedString(
                    challenge.kind.titleKey,
                    bundle: .module,
                    comment: ""
                )
                Text(
                    "gamification.weeklyChallenge.celebrationMessage \(name) \(challenge.kind.rewardPoints)",
                    bundle: .module
                )
            }
            .alert(
                Text(
                    LocalizedStringKey(store.celebratingMilestone?.titleKey ?? ""),
                    bundle: .module
                ),
                isPresented: milestoneCelebrationPresented,
                presenting: store.celebratingMilestone
            ) { _ in
                Button {
                    store.send(.celebrationDismissed)
                } label: {
                    Text("gamification.celebration.dismiss", bundle: .module)
                }
            } message: { milestone in
                Text(LocalizedStringKey(milestone.descriptionKey), bundle: .module)
            }
            .alert(
                Text(
                    LocalizedStringKey(store.celebratingAchievement?.titleKey ?? ""),
                    bundle: .module
                ),
                isPresented: achievementCelebrationPresented,
                presenting: store.celebratingAchievement
            ) { _ in
                Button {
                    store.send(.achievementCelebrationDismissed)
                } label: {
                    Text("gamification.achievements.dismiss", bundle: .module)
                }
            } message: { achievement in
                Text(LocalizedStringKey(achievement.descriptionKey), bundle: .module)
            }
        }
    }

    private var financialLevelCelebrationPresented: Binding<Bool> {
        Binding(
            get: { store.celebratingFinancialLevel != nil },
            set: { isPresented in
                if isPresented == false {
                    store.send(.financialLevelCelebrationDismissed)
                }
            }
        )
    }

    private var weeklyChallengeCelebrationPresented: Binding<Bool> {
        Binding(
            get: {
                store.celebratingFinancialLevel == nil
                    && store.celebratingWeeklyChallenge != nil
            },
            set: { isPresented in
                if isPresented == false {
                    store.send(.weeklyChallengeCelebrationDismissed)
                }
            }
        )
    }

    private var milestoneCelebrationPresented: Binding<Bool> {
        Binding(
            get: {
                store.celebratingFinancialLevel == nil
                    && store.celebratingWeeklyChallenge == nil
                    && store.celebratingMilestone != nil
            },
            set: { isPresented in
                if isPresented == false {
                    store.send(.celebrationDismissed)
                }
            }
        )
    }

    private var achievementCelebrationPresented: Binding<Bool> {
        Binding(
            get: {
                store.celebratingFinancialLevel == nil
                    && store.celebratingWeeklyChallenge == nil
                    && store.celebratingMilestone == nil
                    && store.celebratingAchievement != nil
            },
            set: { isPresented in
                if isPresented == false {
                    store.send(.achievementCelebrationDismissed)
                }
            }
        )
    }
}

public struct GamificationRootView: View {
    private let store: StoreOf<GamificationFeature>

    public init() {
        store = Store(initialState: GamificationFeature.State()) {
            GamificationFeature()
        } withDependencies: {
            $0.gamificationProfileRepository = .preview
            $0.gamificationContextClient = .preview
        }
    }

    public var body: some View {
        GamificationView(store: store)
    }
}

private struct GamificationErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.kaso.destructive)
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
