import ComposableArchitecture
import Foundation
import FutureSelfDomain

private enum FutureSelfContextClientKey: DependencyKey {
    static let liveValue = FutureSelfContextClient.empty
    static let previewValue = FutureSelfContextClient.preview
    static let testValue = FutureSelfContextClient.empty
}

public extension DependencyValues {
    var futureSelfContextClient: FutureSelfContextClient {
        get { self[FutureSelfContextClientKey.self] }
        set { self[FutureSelfContextClientKey.self] = newValue }
    }
}
