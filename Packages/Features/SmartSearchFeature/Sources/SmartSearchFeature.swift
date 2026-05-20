import ComposableArchitecture
import Foundation
import SmartSearchDomain

@Reducer
public struct SmartSearchFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var queryText: String
        public var lastQuery: SmartSearchQuery?

        public init(queryText: String = "", lastQuery: SmartSearchQuery? = nil) {
            self.queryText = queryText
            self.lastQuery = lastQuery
        }
    }

    public enum Action: Equatable, Sendable {
        case queryTextChanged(String)
        case parseRequested
        case exampleTapped(String)
    }

    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .queryTextChanged(text):
                state.queryText = text
                return .none

            case .parseRequested:
                let parsed = SmartSearchParser.parse(
                    state.queryText,
                    referenceDate: date.now
                )
                state.lastQuery = parsed
                return .none

            case let .exampleTapped(example):
                state.queryText = example
                state.lastQuery = SmartSearchParser.parse(
                    example,
                    referenceDate: date.now
                )
                return .none
            }
        }
    }
}
