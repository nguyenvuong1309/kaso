import ComposableArchitecture
import Foundation
import SpendingMapDomain

private enum SpendingMapRepositoryKey: DependencyKey {
    static let liveValue = SpendingMapRepository.empty
    static let previewValue = SpendingMapRepository.preview
    static let testValue = SpendingMapRepository.empty
}

public extension DependencyValues {
    var spendingMapRepository: SpendingMapRepository {
        get { self[SpendingMapRepositoryKey.self] }
        set { self[SpendingMapRepositoryKey.self] = newValue }
    }
}
