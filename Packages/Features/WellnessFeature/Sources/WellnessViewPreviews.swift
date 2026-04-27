import ComposableArchitecture
import SwiftUI

#Preview("Wellness Light") {
    WellnessView(store: previewStore)
}

#Preview("Wellness Dark") {
    WellnessView(store: previewStore)
        .preferredColorScheme(.dark)
}

#Preview("Wellness Dynamic Type XL") {
    WellnessView(store: previewStore)
        .environment(\.dynamicTypeSize, .accessibility1)
}

@MainActor
private var previewStore: StoreOf<WellnessFeature> {
    Store(initialState: WellnessFeature.State()) {
        WellnessFeature()
    }
}
