import Foundation
import ComposableArchitecture
import SleepCorrelationDomain

@Reducer
public struct SleepCorrelationFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var healthAuthorizationStatus: HealthAuthorizationStatus
        public var dataPoints: [SleepSpendingDataPoint]
        public var insight: SleepCorrelationInsight?
        public var selectedPeriod: SleepCorrelationPeriod
        public var isLoading: Bool
        public var isInsightExpanded: Bool
        public var errorMessageKey: String?

        public init(
            healthAuthorizationStatus: HealthAuthorizationStatus = .notDetermined,
            dataPoints: [SleepSpendingDataPoint] = [],
            insight: SleepCorrelationInsight? = nil,
            selectedPeriod: SleepCorrelationPeriod = .lastThirtyDays,
            isLoading: Bool = false,
            isInsightExpanded: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.healthAuthorizationStatus = healthAuthorizationStatus
            self.dataPoints = dataPoints
            self.insight = insight
            self.selectedPeriod = selectedPeriod
            self.isLoading = isLoading
            self.isInsightExpanded = isInsightExpanded
            self.errorMessageKey = errorMessageKey
        }

        public var filteredDataPoints: [SleepSpendingDataPoint] {
            SleepSpendingDataBuilder.filter(
                dataPoints: dataPoints,
                period: selectedPeriod,
                referenceDate: Date()
            )
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case authorizationStatusLoaded(HealthAuthorizationStatus)
        case requestHealthKitPermission
        case healthKitPermissionResponse(Bool)
        case loadData
        case dataLoaded([SleepSpendingDataPoint])
        case loadFailed(String)
        case periodChanged(SleepCorrelationPeriod)
        case insightExpandedToggled
    }

    @Dependency(\.healthSleepClient) private var healthSleepClient
    @Dependency(\.sleepCorrelationDataClient) private var dataClient
    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    await send(.authorizationStatusLoaded(await healthSleepClient.authorizationStatus()))
                }

            case let .authorizationStatusLoaded(status):
                state.healthAuthorizationStatus = status
                if status == .sharingAuthorized {
                    return .send(.loadData)
                } else {
                    state.isLoading = false
                    return .none
                }

            case .requestHealthKitPermission:
                guard state.healthAuthorizationStatus != .sharingAuthorized else {
                    return .send(.loadData)
                }
                state.isLoading = true
                return .run { send in
                    do {
                        await send(.healthKitPermissionResponse(try await healthSleepClient.requestAuthorization()))
                    } catch {
                        await send(.loadFailed("sleep.error.permissionFailed"))
                    }
                }

            case let .healthKitPermissionResponse(granted):
                state.healthAuthorizationStatus = granted ? .sharingAuthorized : .sharingDenied
                if granted {
                    return .send(.loadData)
                } else {
                    state.isLoading = false
                    return .none
                }

            case .loadData:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        await send(.dataLoaded(try await dataClient.loadDataPoints()))
                    } catch {
                        await send(.loadFailed("sleep.error.loadFailed"))
                    }
                }

            case let .dataLoaded(points):
                state.isLoading = false
                state.dataPoints = points
                recomputeInsight(&state)
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case let .periodChanged(period):
                state.selectedPeriod = period
                recomputeInsight(&state)
                return .none

            case .insightExpandedToggled:
                state.isInsightExpanded.toggle()
                return .none
            }
        }
    }

    private func recomputeInsight(_ state: inout State) {
        let filtered = SleepSpendingDataBuilder.filter(
            dataPoints: state.dataPoints,
            period: state.selectedPeriod,
            referenceDate: date.now
        )
        state.insight = SleepCorrelationAnalyzer.compute(dataPoints: filtered)
    }
}
