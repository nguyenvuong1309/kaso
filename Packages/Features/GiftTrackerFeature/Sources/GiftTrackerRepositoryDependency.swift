import ComposableArchitecture
import Foundation
import GiftTrackerDomain

private enum GiftTrackerRepositoryKey: DependencyKey {
    static let liveValue = GiftTrackerRepository.empty
    static let previewValue = GiftTrackerRepository.preview
    static let testValue = GiftTrackerRepository.empty
}

public extension DependencyValues {
    var giftTrackerRepository: GiftTrackerRepository {
        get { self[GiftTrackerRepositoryKey.self] }
        set { self[GiftTrackerRepositoryKey.self] = newValue }
    }
}
