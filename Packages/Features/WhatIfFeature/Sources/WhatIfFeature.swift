import ComposableArchitecture
import Foundation
import WhatIfDomain

@Reducer
public struct WhatIfFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var baseline: WhatIfBaseline
        public var scenario: WhatIfScenario
        public var goalText: String
        public var isLoadingBaseline: Bool
        public var hasLoadedBaseline: Bool
        public var errorMessageKey: String?

        public init(
            baseline: WhatIfBaseline = .empty,
            scenario: WhatIfScenario = WhatIfScenario(),
            goalText: String = "",
            isLoadingBaseline: Bool = false,
            hasLoadedBaseline: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.baseline = baseline
            self.scenario = scenario
            self.goalText = goalText
            self.isLoadingBaseline = isLoadingBaseline
            self.hasLoadedBaseline = hasLoadedBaseline
            self.errorMessageKey = errorMessageKey
        }

        public var projection: WhatIfProjection {
            WhatIfCalculator.project(scenario)
        }

        public var monthsToHitGoalIncludingBeyondHorizon: Int? {
            WhatIfCalculator.breakdownToHitGoal(scenario)
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case baselineLoaded(WhatIfBaseline)
        case baselineLoadFailed(String)
        case incomeDeltaChanged(Decimal)
        case expenseDeltaChanged(Decimal)
        case additionalSavingsChanged(Decimal)
        case horizonChanged(Int)
        case returnRateChanged(Double)
        case goalTextChanged(String)
        case resetTapped
    }

    @Dependency(\.whatIfBaselineClient) private var baselineClient

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                if state.hasLoadedBaseline {
                    return .none
                }
                state.isLoadingBaseline = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let baseline = try await baselineClient.load()
                        await send(.baselineLoaded(baseline))
                    } catch {
                        await send(.baselineLoadFailed("whatIf.error.loadFailed"))
                    }
                }

            case let .baselineLoaded(baseline):
                state.isLoadingBaseline = false
                state.hasLoadedBaseline = true
                state.baseline = baseline
                state.scenario.monthlyIncome = baseline.monthlyIncome
                state.scenario.monthlyExpenses = baseline.monthlyExpenses
                return .none

            case let .baselineLoadFailed(messageKey):
                state.isLoadingBaseline = false
                state.hasLoadedBaseline = true
                state.errorMessageKey = messageKey
                return .none

            case let .incomeDeltaChanged(delta):
                state.scenario.incomeDelta = delta
                return .none

            case let .expenseDeltaChanged(delta):
                state.scenario.expenseDelta = delta
                return .none

            case let .additionalSavingsChanged(amount):
                state.scenario.additionalSavings = amount
                return .none

            case let .horizonChanged(months):
                state.scenario.horizonMonths = months
                return .none

            case let .returnRateChanged(rate):
                state.scenario.annualInvestmentReturnRate = rate
                return .none

            case let .goalTextChanged(text):
                state.goalText = text
                state.scenario.goalAmount = WhatIfAmountParser.parse(text)
                return .none

            case .resetTapped:
                state.scenario = WhatIfScenario(
                    monthlyIncome: state.baseline.monthlyIncome,
                    monthlyExpenses: state.baseline.monthlyExpenses,
                    horizonMonths: state.scenario.horizonMonths,
                    annualInvestmentReturnRate: state.scenario.annualInvestmentReturnRate,
                    goalAmount: state.scenario.goalAmount
                )
                return .none
            }
        }
    }
}

public enum WhatIfAmountParser {
    public static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return nil
        }
        return Decimal(string: cleaned)
    }
}
