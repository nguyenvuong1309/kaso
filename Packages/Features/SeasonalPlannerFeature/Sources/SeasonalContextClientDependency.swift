import ComposableArchitecture
import SeasonalPlannerDomain

private enum SeasonalContextClientKey: DependencyKey {
    static let liveValue = SeasonalContextClient.empty
    static let previewValue = SeasonalContextClient.preview
    static let testValue = SeasonalContextClient.empty
}

public extension DependencyValues {
    var seasonalContextClient: SeasonalContextClient {
        get { self[SeasonalContextClientKey.self] }
        set { self[SeasonalContextClientKey.self] = newValue }
    }
}
