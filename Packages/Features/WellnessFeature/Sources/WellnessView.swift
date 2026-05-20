import BNPLFeature
import BillSplitterFeature
import CloudSyncFeature
import CommunityChallengeFeature
import ComposableArchitecture
import CompatibilityFeature
import CoolingOffFeature
import FreelancerFeature
import FutureSelfFeature
import GamificationFeature
import GiftTrackerFeature
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import HuiTrackerFeature
import KasoDesignSystem
import LegacyFeature
import MoneyPersonalityFeature
import MoneyTherapistFeature
import MoodJournalFeature
import PhantomExpenseFeature
import RegretScoreFeature
import RemindersFeature
import RoundUpFeature
import SeasonalPlannerFeature
import SleepCorrelationFeature
import SmartSearchFeature
import SpendingCalendarFeature
import SpendingDNAFeature
import SpendingMapFeature
import SwiftUI
import WhatIfFeature
import WrappedFeature

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
            case .giftTracker:
                GiftTrackerView(
                    store: store.scope(state: \.giftTracker, action: \.giftTracker)
                )
            case .huiTracker:
                HuiTrackerView(
                    store: store.scope(state: \.huiTracker, action: \.huiTracker)
                )
            case .bnpl:
                BNPLView(
                    store: store.scope(state: \.bnpl, action: \.bnpl)
                )
            case .moneyPersonality:
                MoneyPersonalityView(
                    store: store.scope(state: \.moneyPersonality, action: \.moneyPersonality)
                )
            case .spendingDNA:
                SpendingDNAView(
                    store: store.scope(state: \.spendingDNA, action: \.spendingDNA)
                )
            case .futureSelf:
                FutureSelfView(
                    store: store.scope(state: \.futureSelf, action: \.futureSelf)
                )
            case .wrapped:
                WrappedView(
                    store: store.scope(state: \.wrapped, action: \.wrapped)
                )
            case .seasonalPlanner:
                SeasonalPlannerView(
                    store: store.scope(state: \.seasonalPlanner, action: \.seasonalPlanner)
                )
            case .moneyTherapist:
                MoneyTherapistView(
                    store: store.scope(state: \.moneyTherapist, action: \.moneyTherapist)
                )
            case .communityChallenge:
                CommunityChallengeView(
                    store: store.scope(
                        state: \.communityChallenge,
                        action: \.communityChallenge
                    )
                )
            case .reminders:
                RemindersView(
                    store: store.scope(state: \.reminders, action: \.reminders)
                )
            case .billSplitter:
                BillSplitterView(
                    store: store.scope(state: \.billSplitter, action: \.billSplitter)
                )
            case .smartSearch:
                SmartSearchView(
                    store: store.scope(state: \.smartSearch, action: \.smartSearch)
                )
            case .spendingMap:
                SpendingMapView(
                    store: store.scope(state: \.spendingMap, action: \.spendingMap)
                )
            case .cloudSync:
                CloudSyncView(
                    store: store.scope(state: \.cloudSync, action: \.cloudSync)
                )
            }
        }
    }
}
