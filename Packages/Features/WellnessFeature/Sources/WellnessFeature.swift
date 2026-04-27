import ComposableArchitecture
import HoursOfLifeFeature
import PhantomExpenseFeature

@Reducer
public struct WellnessFeature: Sendable {
    public enum Section: String, CaseIterable, Equatable, Sendable, Identifiable {
        case hoursOfLife
        case phantomExpense

        public var id: String {
            rawValue
        }

        public var titleKey: String {
            switch self {
            case .hoursOfLife:
                "wellness.section.hoursOfLife"
            case .phantomExpense:
                "wellness.section.phantomExpense"
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var section: Section
        public var hoursOfLife: HoursOfLifeFeature.State
        public var phantomExpense: PhantomExpenseFeature.State

        public init(
            section: Section = .hoursOfLife,
            hoursOfLife: HoursOfLifeFeature.State = HoursOfLifeFeature.State(),
            phantomExpense: PhantomExpenseFeature.State = PhantomExpenseFeature.State()
        ) {
            self.section = section
            self.hoursOfLife = hoursOfLife
            self.phantomExpense = phantomExpense
        }
    }

    public enum Action: Equatable, Sendable {
        case sectionChanged(Section)
        case hoursOfLife(HoursOfLifeFeature.Action)
        case phantomExpense(PhantomExpenseFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.hoursOfLife, action: \.hoursOfLife) {
            HoursOfLifeFeature()
        }

        Scope(state: \.phantomExpense, action: \.phantomExpense) {
            PhantomExpenseFeature()
        }

        Reduce { state, action in
            switch action {
            case let .sectionChanged(section):
                state.section = section
                return .none

            case .hoursOfLife, .phantomExpense:
                return .none
            }
        }
    }
}
