import Foundation
import Testing
@testable import AuthDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}

@Test("init stores all provided fields")
func authSessionInitStoresFields() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15, hour: 9)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com",
        signedInAt: date
    )

    #expect(session.userIdentifier == "user-1")
    #expect(session.displayName == "Vuong")
    #expect(session.email == "vuong@example.com")
    #expect(session.signedInAt == date)
}

@Test("init defaults optional fields to nil")
func authSessionInitDefaultsNil() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)

    #expect(session.displayName == nil)
    #expect(session.email == nil)
}

@Test("preferredDisplayName prefers non-empty display name")
func preferredDisplayNamePrefersDisplayName() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com",
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "Vuong")
}

@Test("preferredDisplayName falls back to email when display name is nil")
func preferredDisplayNameFallsBackToEmailWhenNil() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: nil,
        email: "vuong@example.com",
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "vuong@example.com")
}

@Test("preferredDisplayName falls back to email when display name is empty")
func preferredDisplayNameFallsBackToEmailWhenEmpty() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: "",
        email: "vuong@example.com",
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "vuong@example.com")
}

@Test("preferredDisplayName uses default key when display name and email both empty")
func preferredDisplayNameDefaultWhenBothEmpty() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: "",
        email: "",
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "auth.user.defaultName")
}

@Test("preferredDisplayName uses default key when display name and email both nil")
func preferredDisplayNameDefaultWhenBothNil() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)

    #expect(session.preferredDisplayName == "auth.user.defaultName")
}

@Test("preferredDisplayName falls back to default when display name empty and email nil")
func preferredDisplayNameDefaultWhenEmptyDisplayAndNilEmail() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let session = AuthSession(
        userIdentifier: "user-1",
        displayName: "",
        email: nil,
        signedInAt: date
    )

    #expect(session.preferredDisplayName == "auth.user.defaultName")
}

@Test("equatable distinguishes by user identifier")
func authSessionEquatableByUserIdentifier() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let lhs = AuthSession(userIdentifier: "user-1", signedInAt: date)
    let rhs = AuthSession(userIdentifier: "user-2", signedInAt: date)

    #expect(lhs != rhs)
}

@Test("equatable treats identical sessions as equal")
func authSessionEquatableEqual() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15, hour: 8)
    let lhs = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com",
        signedInAt: date
    )
    let rhs = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com",
        signedInAt: date
    )

    #expect(lhs == rhs)
}

@Test("equatable distinguishes by signed-in date")
func authSessionEquatableByDate() throws {
    let early = try makeDate(year: 2026, month: 1, day: 15, hour: 8)
    let late = try makeDate(year: 2026, month: 1, day: 15, hour: 9)
    let lhs = AuthSession(userIdentifier: "user-1", signedInAt: early)
    let rhs = AuthSession(userIdentifier: "user-1", signedInAt: late)

    #expect(lhs != rhs)
}

@Test("codable round-trips with all fields populated")
func authSessionCodableRoundTrip() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15, hour: 10)
    let original = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com",
        signedInAt: date
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AuthSession.self, from: data)

    #expect(decoded == original)
}

@Test("codable round-trips with nil optional fields")
func authSessionCodableRoundTripNilFields() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    let original = AuthSession(userIdentifier: "user-1", signedInAt: date)

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AuthSession.self, from: data)

    #expect(decoded == original)
    #expect(decoded.displayName == nil)
    #expect(decoded.email == nil)
}

@Test("mutating a var property updates the value")
func authSessionMutability() throws {
    let date = try makeDate(year: 2026, month: 1, day: 15)
    var session = AuthSession(userIdentifier: "user-1", signedInAt: date)
    session.displayName = "Updated"

    #expect(session.displayName == "Updated")
    #expect(session.preferredDisplayName == "Updated")
}
