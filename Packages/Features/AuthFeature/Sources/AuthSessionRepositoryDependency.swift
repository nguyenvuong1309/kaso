import AuthDomain
import ComposableArchitecture
import Foundation

private enum AuthSessionRepositoryKey: DependencyKey {
    static let liveValue = AuthSessionRepository.empty
    static let previewValue = AuthSessionRepository.preview
    static let testValue = AuthSessionRepository.empty
}

public extension AuthSessionRepository {
    static let preview = AuthSessionRepository(
        load: {
            AuthSession(
                userIdentifier: "preview-user",
                displayName: "Kaso User",
                signedInAt: Date()
            )
        },
        save: { _ in },
        clear: {}
    )
}

public extension DependencyValues {
    var authSessionRepository: AuthSessionRepository {
        get { self[AuthSessionRepositoryKey.self] }
        set { self[AuthSessionRepositoryKey.self] = newValue }
    }
}
