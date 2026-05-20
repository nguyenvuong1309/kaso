import ComposableArchitecture
import Foundation
import FutureSelfDomain

@Reducer
public struct FutureSelfFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var letter: FutureSelfLetter
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            letter: FutureSelfLetter = .empty,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.letter = letter
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case letterLoaded(FutureSelfLetter)
        case loadFailed(String)
    }

    @Dependency(\.futureSelfContextClient) private var contextClient

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let context = try await contextClient.loadContext()
                        let letter = FutureSelfLetterBuilder.build(context: context)
                        await send(.letterLoaded(letter))
                    } catch {
                        await send(.loadFailed("futureSelf.error.loadFailed"))
                    }
                }

            case let .letterLoaded(letter):
                state.isLoading = false
                state.letter = letter
                return .none

            case let .loadFailed(key):
                state.isLoading = false
                state.errorMessageKey = key
                return .none
            }
        }
    }
}
