import BNPLDomain
import ComposableArchitecture
import Foundation

private enum BNPLRepositoryKey: DependencyKey {
    static let liveValue = BNPLRepository.empty
    static let previewValue = BNPLRepository.preview
    static let testValue = BNPLRepository.empty
}

private enum BNPLContextClientKey: DependencyKey {
    static let liveValue = BNPLContextClient.empty
    static let previewValue = BNPLContextClient.preview
    static let testValue = BNPLContextClient.empty
}

public extension DependencyValues {
    var bnplRepository: BNPLRepository {
        get { self[BNPLRepositoryKey.self] }
        set { self[BNPLRepositoryKey.self] = newValue }
    }

    var bnplContextClient: BNPLContextClient {
        get { self[BNPLContextClientKey.self] }
        set { self[BNPLContextClientKey.self] = newValue }
    }
}
