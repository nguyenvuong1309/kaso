import ComposableArchitecture
import CompatibilityFeature
import CoolingOffFeature
import FreelancerFeature
import GamificationFeature
import GuiltFreeBudgetFeature
import HoursOfLifeFeature
import LegacyFeature
import MoodJournalFeature
import PhantomExpenseFeature
import RegretScoreFeature
import RoundUpFeature
import SleepCorrelationFeature
import SpendingCalendarFeature
import WhatIfFeature

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
            legacy: LegacyFeature.State = LegacyFeature.State()
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

        Reduce { state, action in
            switch action {
            case let .sectionChanged(section):
                state.section = section
                return .none

            case .gamification, .hoursOfLife, .spendingCalendar, .whatIf,
                 .phantomExpense, .roundUp, .guiltFreeBudget, .coolingOff,
                 .moodJournal, .regretScore, .compatibility, .freelancer,
                 .sleepCorrelation, .legacy:
                return .none
            }
        }
    }
}
