import ComposableArchitecture
import CompatibilityFeature
import FreelancerFeature
import GamificationFeature
import HoursOfLifeFeature
import LegacyFeature
import PhantomExpenseFeature
import SleepCorrelationFeature

@Reducer
public struct WellnessFeature: Sendable {
    public enum Section: String, CaseIterable, Equatable, Sendable, Identifiable {
        case gamification
        case hoursOfLife
        case phantomExpense
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
            case .phantomExpense:
                "wellness.section.phantomExpense"
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
        public var phantomExpense: PhantomExpenseFeature.State
        public var compatibility: CompatibilityFeature.State
        public var freelancer: FreelancerFeature.State
        public var sleepCorrelation: SleepCorrelationFeature.State
        public var legacy: LegacyFeature.State

        public init(
            section: Section = .gamification,
            gamification: GamificationFeature.State = GamificationFeature.State(),
            hoursOfLife: HoursOfLifeFeature.State = HoursOfLifeFeature.State(),
            phantomExpense: PhantomExpenseFeature.State = PhantomExpenseFeature.State(),
            compatibility: CompatibilityFeature.State = CompatibilityFeature.State(),
            freelancer: FreelancerFeature.State = FreelancerFeature.State(),
            sleepCorrelation: SleepCorrelationFeature.State = SleepCorrelationFeature.State(),
            legacy: LegacyFeature.State = LegacyFeature.State()
        ) {
            self.section = section
            self.gamification = gamification
            self.hoursOfLife = hoursOfLife
            self.phantomExpense = phantomExpense
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
        case phantomExpense(PhantomExpenseFeature.Action)
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

        Scope(state: \.phantomExpense, action: \.phantomExpense) {
            PhantomExpenseFeature()
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

            case .gamification, .hoursOfLife, .phantomExpense, .compatibility,
                 .freelancer, .sleepCorrelation, .legacy:
                return .none
            }
        }
    }
}
