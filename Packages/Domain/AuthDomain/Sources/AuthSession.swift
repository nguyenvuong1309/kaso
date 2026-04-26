import Foundation

public struct AuthSession: Codable, Equatable, Sendable {
    public var userIdentifier: String
    public var displayName: String?
    public var email: String?
    public var signedInAt: Date

    public init(
        userIdentifier: String,
        displayName: String? = nil,
        email: String? = nil,
        signedInAt: Date
    ) {
        self.userIdentifier = userIdentifier
        self.displayName = displayName
        self.email = email
        self.signedInAt = signedInAt
    }

    public var preferredDisplayName: String {
        if let displayName, displayName.isEmpty == false {
            return displayName
        }

        if let email, email.isEmpty == false {
            return email
        }

        return "auth.user.defaultName"
    }
}
