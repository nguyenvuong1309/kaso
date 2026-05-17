import ComposableArchitecture
import CompatibilityFeature
import CoolingOffFeature
import FreelancerFeature
import GamificationFeature
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import KasoDesignSystem
import LegacyFeature
import MoodJournalFeature
import PhantomExpenseFeature
import RegretScoreFeature
import RoundUpFeature
import SleepCorrelationFeature
import SpendingCalendarFeature
import SwiftUI
import WhatIfFeature

public struct WellnessView: View {
    @Bindable private var store: StoreOf<WellnessFeature>

    public init(store: StoreOf<WellnessFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                Picker(
                    selection: $store.section.sending(\.sectionChanged)
                ) {
                    ForEach(WellnessFeature.Section.allCases) { section in
                        Text(LocalizedStringKey(section.titleKey), bundle: .module)
                            .tag(section)
                    }
                } label: {
                    Text("wellness.section.label", bundle: .module)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .background(Color.kaso.surfacePrimary)

            switch store.section {
            case .gamification:
                GamificationView(
                    store: store.scope(state: \.gamification, action: \.gamification)
                )
            case .hoursOfLife:
                HoursOfLifeView(
                    store: store.scope(state: \.hoursOfLife, action: \.hoursOfLife)
                )
            case .spendingCalendar:
                SpendingCalendarView(
                    store: store.scope(state: \.spendingCalendar, action: \.spendingCalendar)
                )
            case .whatIf:
                WhatIfView(
                    store: store.scope(state: \.whatIf, action: \.whatIf)
                )
            case .phantomExpense:
                PhantomExpenseView(
                    store: store.scope(state: \.phantomExpense, action: \.phantomExpense)
                )
            case .roundUp:
                RoundUpView(
                    store: store.scope(state: \.roundUp, action: \.roundUp)
                )
            case .guiltFreeBudget:
                GuiltFreeBudgetView(
                    store: store.scope(state: \.guiltFreeBudget, action: \.guiltFreeBudget)
                )
            case .coolingOff:
                CoolingOffView(
                    store: store.scope(state: \.coolingOff, action: \.coolingOff)
                )
            case .moodJournal:
                MoodJournalView(
                    store: store.scope(state: \.moodJournal, action: \.moodJournal)
                )
            case .regretScore:
                RegretScoreView(
                    store: store.scope(state: \.regretScore, action: \.regretScore)
                )
            case .compatibility:
                CompatibilityView(
                    store: store.scope(state: \.compatibility, action: \.compatibility)
                )
            case .freelancer:
                FreelancerView(
                    store: store.scope(state: \.freelancer, action: \.freelancer)
                )
            case .sleepCorrelation:
                SleepCorrelationView(
                    store: store.scope(state: \.sleepCorrelation, action: \.sleepCorrelation)
                )
            case .legacy:
                LegacyView(
                    store: store.scope(state: \.legacy, action: \.legacy)
                )
            }
        }
    }
}
