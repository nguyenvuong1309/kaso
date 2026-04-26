import AuthDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct AuthFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var session: AuthSession?
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            session: AuthSession? = nil,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.session = session
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case sessionLoaded(AuthSession?)
        case loadFailed(String)
        case signInSucceeded(AuthSignInResult)
        case signInFailed(String)
        case sessionSaved(AuthSession)
        case saveFailed(String)
        case signOutButtonTapped
        case signedOut
        case signOutFailed(String)
    }

    @Dependency(\.authSessionRepository) private var repository
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        let session = try await repository.load()
                        await send(.sessionLoaded(session))
                    } catch {
                        await send(.loadFailed("auth.error.loadFailed"))
                    }
                }

            case let .sessionLoaded(session):
                state.isLoading = false
                state.session = session
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .signInSucceeded(result):
                let session = result.session(signedInAt: now)
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        try await repository.save(session)
                        await send(.sessionSaved(session))
                    } catch {
                        await send(.saveFailed("auth.error.saveFailed"))
                    }
                }

            case let .signInFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .sessionSaved(session):
                state.isLoading = false
                state.session = session
                return .none

            case let .saveFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .signOutButtonTapped:
                state.isLoading = true
                state.errorMessageKey = nil

                return .run { send in
                    do {
                        try await repository.clear()
                        await send(.signedOut)
                    } catch {
                        await send(.signOutFailed("auth.error.signOutFailed"))
                    }
                }

            case .signedOut:
                state.isLoading = false
                state.session = nil
                return .none

            case let .signOutFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none
            }
        }
    }
}
