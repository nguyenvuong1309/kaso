import SwiftUI
import ComposableArchitecture

#Preview("Light") {
    FreelancerView(
        store: Store(initialState: FreelancerFeature.State()) {
            FreelancerFeature()
        } withDependencies: {
            $0.freelancerProfileRepository = .preview
        }
    )
}

#Preview("Dark") {
    FreelancerView(
        store: Store(initialState: FreelancerFeature.State()) {
            FreelancerFeature()
        } withDependencies: {
            $0.freelancerProfileRepository = .preview
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    FreelancerView(
        store: Store(initialState: FreelancerFeature.State()) {
            FreelancerFeature()
        } withDependencies: {
            $0.freelancerProfileRepository = .preview
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
