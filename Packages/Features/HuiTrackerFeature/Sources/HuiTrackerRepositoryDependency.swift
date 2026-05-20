import ComposableArchitecture
import Foundation
import HuiTrackerDomain

private enum HuiTrackerRepositoryKey: DependencyKey {
    static let liveValue = HuiTrackerRepository.empty
    static let previewValue = HuiTrackerRepository.preview
    static let testValue = HuiTrackerRepository.empty
}

public extension DependencyValues {
    var huiTrackerRepository: HuiTrackerRepository {
        get { self[HuiTrackerRepositoryKey.self] }
        set { self[HuiTrackerRepositoryKey.self] = newValue }
    }
}
