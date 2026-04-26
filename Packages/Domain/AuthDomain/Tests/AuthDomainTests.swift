import Foundation
import Testing
@testable import AuthDomain

@Test("creates session from sign in result")
func createsSessionFromSignInResult() throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let result = AuthSignInResult(
        userIdentifier: "apple-user-id",
        displayName: "Vuong",
        email: "vuong@example.com"
    )

    let session = result.session(signedInAt: date)

    #expect(session.userIdentifier == "apple-user-id")
    #expect(session.displayName == "Vuong")
    #expect(session.email == "vuong@example.com")
    #expect(session.signedInAt == date)
}

@Test("falls back to default display name key")
func fallsBackToDefaultDisplayNameKey() throws {
    let date = try #require(
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2026,
            month: 4,
            day: 26
        ).date
    )
    let session = AuthSession(
        userIdentifier: "apple-user-id",
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "auth.user.defaultName")
}
