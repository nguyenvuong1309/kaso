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
import WhatIfFeature
import WrappedFeature

@Reducer
public struct WellnessFeature: Sendable {
    public enum Section: String, CaseIterable, Equatable, Sendable, Identifiable {
        case gamification
        case hoursOfLife
        case spendingCalendar
        case whatIf
        case phantomExpense
        case roundUp
        case guiltFreeBudget
        case coolingOff
        case moodJournal
        case regretScore
        case compatibility
        case freelancer
        case sleepCorrelation
        case legacy
        case giftTracker
        case huiTracker
        case bnpl
        case moneyPersonality
        case spendingDNA
        case futureSelf
        case wrapped
        case seasonalPlanner
        case moneyTherapist
        case communityChallenge
        case reminders
        case billSplitter
        case smartSearch
        case spendingMap
        case cloudSync

        public var id: String {
            rawValue
        }

        public var titleKey: String {
            switch self {
            case .gamification:
                "wellness.section.gamification"
            case .hoursOfLife:
                "wellness.section.hoursOfLife"
            case .spendingCalendar:
                "wellness.section.spendingCalendar"
            case .whatIf:
                "wellness.section.whatIf"
            case .phantomExpense:
                "wellness.section.phantomExpense"
            case .roundUp:
                "wellness.section.roundUp"
            case .guiltFreeBudget:
                "wellness.section.guiltFreeBudget"
            case .coolingOff:
                "wellness.section.coolingOff"
            case .moodJournal:
                "wellness.section.moodJournal"
            case .regretScore:
                "wellness.section.regretScore"
            case .compatibility:
                "wellness.section.compatibility"
            case .freelancer:
                "wellness.section.freelancer"
            case .sleepCorrelation:
                "wellness.section.sleepCorrelation"
            case .legacy:
                "wellness.section.legacy"
            case .giftTracker:
                "wellness.section.giftTracker"
            case .huiTracker:
                "wellness.section.huiTracker"
            case .bnpl:
                "wellness.section.bnpl"
            case .moneyPersonality:
                "wellness.section.moneyPersonality"
            case .spendingDNA:
                "wellness.section.spendingDNA"
            case .futureSelf:
                "wellness.section.futureSelf"
            case .wrapped:
                "wellness.section.wrapped"
            case .seasonalPlanner:
                "wellness.section.seasonalPlanner"
            case .moneyTherapist:
                "wellness.section.moneyTherapist"
            case .communityChallenge:
                "wellness.section.communityChallenge"
            case .reminders:
                "wellness.section.reminders"
            case .billSplitter:
                "wellness.section.billSplitter"
            case .smartSearch:
                "wellness.section.smartSearch"
            case .spendingMap:
                "wellness.section.spendingMap"
            case .cloudSync:
                "wellness.section.cloudSync"
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var section: Section
        public var gamification: GamificationFeature.State
        public var hoursOfLife: HoursOfLifeFeature.State
        public var spendingCalendar: SpendingCalendarFeature.State
        public var whatIf: WhatIfFeature.State
        public var phantomExpense: PhantomExpenseFeature.State
        public var roundUp: RoundUpFeature.State
        public var guiltFreeBudget: GuiltFreeBudgetFeature.State
        public var coolingOff: CoolingOffFeature.State
        public var moodJournal: MoodJournalFeature.State
        public var regretScore: RegretScoreFeature.State
        public var compatibility: CompatibilityFeature.State
        public var freelancer: FreelancerFeature.State
        public var sleepCorrelation: SleepCorrelationFeature.State
        public var legacy: LegacyFeature.State
        public var giftTracker: GiftTrackerFeature.State
        public var huiTracker: HuiTrackerFeature.State
        public var bnpl: BNPLFeature.State
        public var moneyPersonality: MoneyPersonalityFeature.State
        public var spendingDNA: SpendingDNAFeature.State
        public var futureSelf: FutureSelfFeature.State
        public var wrapped: WrappedFeature.State
        public var seasonalPlanner: SeasonalPlannerFeature.State
        public var moneyTherapist: MoneyTherapistFeature.State
        public var communityChallenge: CommunityChallengeFeature.State
        public var reminders: RemindersFeature.State
        public var billSplitter: BillSplitterFeature.State
        public var smartSearch: SmartSearchFeature.State
        public var spendingMap: SpendingMapFeature.State
        public var cloudSync: CloudSyncFeature.State

        public init(
            section: Section = .gamification,
            gamification: GamificationFeature.State = GamificationFeature.State(),
            hoursOfLife: HoursOfLifeFeature.State = HoursOfLifeFeature.State(),
            spendingCalendar: SpendingCalendarFeature.State = SpendingCalendarFeature.State(),
            whatIf: WhatIfFeature.State = WhatIfFeature.State(),
            phantomExpense: PhantomExpenseFeature.State = PhantomExpenseFeature.State(),
            roundUp: RoundUpFeature.State = RoundUpFeature.State(),
            guiltFreeBudget: GuiltFreeBudgetFeature.State = GuiltFreeBudgetFeature.State(),
            coolingOff: CoolingOffFeature.State = CoolingOffFeature.State(),
            moodJournal: MoodJournalFeature.State = MoodJournalFeature.State(),
            regretScore: RegretScoreFeature.State = RegretScoreFeature.State(),
            compatibility: CompatibilityFeature.State = CompatibilityFeature.State(),
            freelancer: FreelancerFeature.State = FreelancerFeature.State(),
            sleepCorrelation: SleepCorrelationFeature.State = SleepCorrelationFeature.State(),
            legacy: LegacyFeature.State = LegacyFeature.State(),
            giftTracker: GiftTrackerFeature.State = GiftTrackerFeature.State(),
            huiTracker: HuiTrackerFeature.State = HuiTrackerFeature.State(),
            bnpl: BNPLFeature.State = BNPLFeature.State(),
            moneyPersonality: MoneyPersonalityFeature.State = MoneyPersonalityFeature.State(),
            spendingDNA: SpendingDNAFeature.State = SpendingDNAFeature.State(),
            futureSelf: FutureSelfFeature.State = FutureSelfFeature.State(),
            wrapped: WrappedFeature.State = WrappedFeature.State(),
            seasonalPlanner: SeasonalPlannerFeature.State = SeasonalPlannerFeature.State(),
            moneyTherapist: MoneyTherapistFeature.State = MoneyTherapistFeature.State(),
            communityChallenge: CommunityChallengeFeature.State = CommunityChallengeFeature.State(),
            reminders: RemindersFeature.State = RemindersFeature.State(),
            billSplitter: BillSplitterFeature.State = BillSplitterFeature.State(),
            smartSearch: SmartSearchFeature.State = SmartSearchFeature.State(),
            spendingMap: SpendingMapFeature.State = SpendingMapFeature.State(),
            cloudSync: CloudSyncFeature.State = CloudSyncFeature.State()
        ) {
            self.section = section
            self.gamification = gamification
            self.hoursOfLife = hoursOfLife
            self.spendingCalendar = spendingCalendar
            self.whatIf = whatIf
            self.phantomExpense = phantomExpense
            self.roundUp = roundUp
            self.guiltFreeBudget = guiltFreeBudget
            self.coolingOff = coolingOff
            self.moodJournal = moodJournal
            self.regretScore = regretScore
            self.compatibility = compatibility
            self.freelancer = freelancer
            self.sleepCorrelation = sleepCorrelation
            self.legacy = legacy
            self.giftTracker = giftTracker
            self.huiTracker = huiTracker
            self.bnpl = bnpl
            self.moneyPersonality = moneyPersonality
            self.spendingDNA = spendingDNA
            self.futureSelf = futureSelf
            self.wrapped = wrapped
            self.seasonalPlanner = seasonalPlanner
            self.moneyTherapist = moneyTherapist
            self.communityChallenge = communityChallenge
            self.reminders = reminders
            self.billSplitter = billSplitter
            self.smartSearch = smartSearch
            self.spendingMap = spendingMap
            self.cloudSync = cloudSync
        }
    }

    public enum Action: Equatable, Sendable {
        case sectionChanged(Section)
        case gamification(GamificationFeature.Action)
        case hoursOfLife(HoursOfLifeFeature.Action)
        case spendingCalendar(SpendingCalendarFeature.Action)
        case whatIf(WhatIfFeature.Action)
        case phantomExpense(PhantomExpenseFeature.Action)
        case roundUp(RoundUpFeature.Action)
        case guiltFreeBudget(GuiltFreeBudgetFeature.Action)
        case coolingOff(CoolingOffFeature.Action)
        case moodJournal(MoodJournalFeature.Action)
        case regretScore(RegretScoreFeature.Action)
        case compatibility(CompatibilityFeature.Action)
        case freelancer(FreelancerFeature.Action)
        case sleepCorrelation(SleepCorrelationFeature.Action)
        case legacy(LegacyFeature.Action)
        case giftTracker(GiftTrackerFeature.Action)
        case huiTracker(HuiTrackerFeature.Action)
        case bnpl(BNPLFeature.Action)
        case moneyPersonality(MoneyPersonalityFeature.Action)
        case spendingDNA(SpendingDNAFeature.Action)
        case futureSelf(FutureSelfFeature.Action)
        case wrapped(WrappedFeature.Action)
        case seasonalPlanner(SeasonalPlannerFeature.Action)
        case moneyTherapist(MoneyTherapistFeature.Action)
        case communityChallenge(CommunityChallengeFeature.Action)
        case reminders(RemindersFeature.Action)
        case billSplitter(BillSplitterFeature.Action)
        case smartSearch(SmartSearchFeature.Action)
        case spendingMap(SpendingMapFeature.Action)
        case cloudSync(CloudSyncFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.gamification, action: \.gamification) {
            GamificationFeature()
        }

        Scope(state: \.hoursOfLife, action: \.hoursOfLife) {
            HoursOfLifeFeature()
        }

        Scope(state: \.spendingCalendar, action: \.spendingCalendar) {
            SpendingCalendarFeature()
        }

        Scope(state: \.whatIf, action: \.whatIf) {
            WhatIfFeature()
        }

        Scope(state: \.phantomExpense, action: \.phantomExpense) {
            PhantomExpenseFeature()
        }

        Scope(state: \.roundUp, action: \.roundUp) {
            RoundUpFeature()
        }

        Scope(state: \.guiltFreeBudget, action: \.guiltFreeBudget) {
            GuiltFreeBudgetFeature()
        }

        Scope(state: \.coolingOff, action: \.coolingOff) {
            CoolingOffFeature()
        }

        Scope(state: \.moodJournal, action: \.moodJournal) {
            MoodJournalFeature()
        }

        Scope(state: \.regretScore, action: \.regretScore) {
            RegretScoreFeature()
        }

        Scope(state: \.compatibility, action: \.compatibility) {
            CompatibilityFeature()
        }

        Scope(state: \.freelancer, action: \.freelancer) {
            FreelancerFeature()
        }

        Scope(state: \.sleepCorrelation, action: \.sleepCorrelation) {
            SleepCorrelationFeature()
        }

        Scope(state: \.legacy, action: \.legacy) {
            LegacyFeature()
        }

        Scope(state: \.giftTracker, action: \.giftTracker) {
            GiftTrackerFeature()
        }

        Scope(state: \.huiTracker, action: \.huiTracker) {
            HuiTrackerFeature()
        }

        Scope(state: \.bnpl, action: \.bnpl) {
            BNPLFeature()
        }

        Scope(state: \.moneyPersonality, action: \.moneyPersonality) {
            MoneyPersonalityFeature()
        }

        Scope(state: \.spendingDNA, action: \.spendingDNA) {
            SpendingDNAFeature()
        }

        Scope(state: \.futureSelf, action: \.futureSelf) {
            FutureSelfFeature()
        }

        Scope(state: \.wrapped, action: \.wrapped) {
            WrappedFeature()
        }

        Scope(state: \.seasonalPlanner, action: \.seasonalPlanner) {
            SeasonalPlannerFeature()
        }

        Scope(state: \.moneyTherapist, action: \.moneyTherapist) {
            MoneyTherapistFeature()
        }

        Scope(state: \.communityChallenge, action: \.communityChallenge) {
            CommunityChallengeFeature()
        }

        Scope(state: \.reminders, action: \.reminders) {
            RemindersFeature()
        }

        Scope(state: \.billSplitter, action: \.billSplitter) {
            BillSplitterFeature()
        }

        Scope(state: \.smartSearch, action: \.smartSearch) {
            SmartSearchFeature()
        }

        Scope(state: \.spendingMap, action: \.spendingMap) {
            SpendingMapFeature()
        }

        Scope(state: \.cloudSync, action: \.cloudSync) {
            CloudSyncFeature()
        }

        Reduce { state, action in
            switch action {
            case let .sectionChanged(section):
                state.section = section
                return .none

            case .gamification, .hoursOfLife, .spendingCalendar, .whatIf,
                 .phantomExpense, .roundUp, .guiltFreeBudget, .coolingOff,
                 .moodJournal, .regretScore, .compatibility, .freelancer,
                 .sleepCorrelation, .legacy, .giftTracker, .huiTracker, .bnpl, .moneyPersonality,
                 .spendingDNA, .futureSelf, .wrapped, .seasonalPlanner, .moneyTherapist,
                 .communityChallenge, .reminders, .billSplitter, .smartSearch,
                 .spendingMap, .cloudSync:
                return .none
            }
        }
    }
}
