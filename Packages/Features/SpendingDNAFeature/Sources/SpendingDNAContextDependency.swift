import ComposableArchitecture
import Foundation
import SpendingDNADomain

private enum SpendingDNAContextClientKey: DependencyKey {
    static let liveValue = SpendingDNAContextClient.empty
    static let previewValue = SpendingDNAContextClient.preview
    static let testValue = SpendingDNAContextClient.empty
}

public extension DependencyValues {
    var spendingDNAContextClient: SpendingDNAContextClient {
        get { self[SpendingDNAContextClientKey.self] }
        set { self[SpendingDNAContextClientKey.self] = newValue }
    }
}
