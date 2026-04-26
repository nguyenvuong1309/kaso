import Foundation

public struct AuthSignInResult: Equatable, Sendable {
    public var userIdentifier: String
    public var displayName: String?
    public var email: String?

    public init(
        userIdentifier: String,
        displayName: String? = nil,
        email: String? = nil
    ) {
        self.userIdentifier = userIdentifier
        self.displayName = displayName
        self.email = email
    }

    public func session(signedInAt: Date) -> AuthSession {
        AuthSession(
            userIdentifier: userIdentifier,
            displayName: displayName,
            email: email,
            signedInAt: signedInAt
        )
    }
}
