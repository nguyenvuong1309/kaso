import SwiftUI
import ComposableArchitecture

#Preview("Light") {
    SleepCorrelationView(
        store: Store(initialState: SleepCorrelationFeature.State()) {
            SleepCorrelationFeature()
        } withDependencies: {
            $0.healthSleepClient = .preview
            $0.sleepCorrelationDataClient = .preview
        }
    )
}

#Preview("Dark") {
    SleepCorrelationView(
        store: Store(initialState: SleepCorrelationFeature.State()) {
            SleepCorrelationFeature()
        } withDependencies: {
            $0.healthSleepClient = .preview
            $0.sleepCorrelationDataClient = .preview
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    SleepCorrelationView(
        store: Store(initialState: SleepCorrelationFeature.State()) {
            SleepCorrelationFeature()
        } withDependencies: {
            $0.healthSleepClient = .preview
            $0.sleepCorrelationDataClient = .preview
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
