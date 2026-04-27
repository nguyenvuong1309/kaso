import Foundation
import ComposableArchitecture
import InsightDomain
import TransactionDomain

@Reducer
public struct BenchmarkFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var isPresented: Bool
        public var isLoading: Bool
        public var transactions: [Transaction]
        public var profile: AnonymousBenchmarkProfile
        public var report: AnonymousBenchmarkReport?
        public var referenceDate: Date
        public var errorMessageKey: String?

        public init(
            isPresented: Bool = false,
            isLoading: Bool = false,
            transactions: [Transaction] = [],
            profile: AnonymousBenchmarkProfile = AnonymousBenchmarkProfile(),
            report: AnonymousBenchmarkReport? = nil,
            referenceDate: Date = Date(timeIntervalSinceReferenceDate: 0),
            errorMessageKey: String? = nil
        ) {
            self.isPresented = isPresented
            self.isLoading = isLoading
            self.transactions = transactions
            self.profile = profile
            self.report = report
            self.referenceDate = referenceDate
            self.errorMessageKey = errorMessageKey
        }
    }

    public enum Action: Equatable, Sendable {
        case floatingButtonTapped
        case sheetDismissed
        case refreshButtonTapped
        case contextLoaded([Transaction], Decimal?)
        case contextLoadFailed
        case cityChanged(AnonymousBenchmarkCity)
        case ageGroupChanged(AnonymousBenchmarkAgeGroup)
        case incomeBandChanged(AnonymousBenchmarkIncomeBand)
    }

    @Dependency(\.benchmarkContextClient) private var contextClient
    @Dependency(\.date.now) private var now

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .floatingButtonTapped:
                state.isPresented = true
                return loadContext(&state)

            case .sheetDismissed:
                state.isPresented = false
                return .none

            case .refreshButtonTapped:
                return loadContext(&state)

            case let .contextLoaded(transactions, monthlyIncome):
                state.isLoading = false
                state.transactions = transactions
                state.profile.incomeBand = AnonymousBenchmarkIncomeBand.inferred(from: monthlyIncome)
                recomputeReport(&state)
                return .none

            case .contextLoadFailed:
                state.isLoading = false
                state.errorMessageKey = "benchmark.error.loadFailed"
                return .none

            case let .cityChanged(city):
                state.profile.city = city
                recomputeReport(&state)
                return .none

            case let .ageGroupChanged(ageGroup):
                state.profile.ageGroup = ageGroup
                recomputeReport(&state)
                return .none

            case let .incomeBandChanged(incomeBand):
                state.profile.incomeBand = incomeBand
                recomputeReport(&state)
                return .none
            }
        }
    }

    private func loadContext(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessageKey = nil
        state.referenceDate = now

        return .run { [contextClient] send in
            do {
                async let transactions = contextClient.loadTransactions()
                async let monthlyIncome = contextClient.defaultMonthlyIncome()
                try await send(.contextLoaded(transactions, monthlyIncome))
            } catch {
                await send(.contextLoadFailed)
            }
        }
    }

    private func recomputeReport(_ state: inout State) {
        state.report = AnonymousBenchmarkReporter.report(
            transactions: state.transactions,
            profile: state.profile,
            referenceDate: state.referenceDate
        )
    }
}
