import ComposableArchitecture
import Foundation
import WrappedDomain

private enum WrappedContextClientKey: DependencyKey {
    static let liveValue = WrappedContextClient.empty
    static let previewValue = WrappedContextClient.preview
    static let testValue = WrappedContextClient.empty
}

public extension DependencyValues {
    var wrappedContextClient: WrappedContextClient {
        get { self[WrappedContextClientKey.self] }
        set { self[WrappedContextClientKey.self] = newValue }
    }
}
