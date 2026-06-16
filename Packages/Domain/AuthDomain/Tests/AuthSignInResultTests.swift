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
func signInResultInitStoresFields() {
    let result = AuthSignInResult(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com"
    )

    #expect(result.userIdentifier == "user-1")
    #expect(result.displayName == "Vuong")
    #expect(result.email == "vuong@example.com")
}

@Test("init defaults optional fields to nil")
func signInResultInitDefaultsNil() {
    let result = AuthSignInResult(userIdentifier: "user-1")

    #expect(result.displayName == nil)
    #expect(result.email == nil)
}

@Test("session maps nil optional fields through unchanged")
func signInResultSessionMapsNilFields() throws {
    let date = try makeDate(year: 2026, month: 5, day: 1, hour: 7)
    let result = AuthSignInResult(userIdentifier: "user-1")

    let session = result.session(signedInAt: date)

    #expect(session.userIdentifier == "user-1")
    #expect(session.displayName == nil)
    #expect(session.email == nil)
    #expect(session.signedInAt == date)
}

@Test("session preserves the exact signed-in date")
func signInResultSessionPreservesDate() throws {
    let date = try makeDate(year: 2026, month: 12, day: 31, hour: 23)
    let result = AuthSignInResult(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com"
    )

    let session = result.session(signedInAt: date)

    #expect(session.signedInAt == date)
    #expect(session.displayName == "Vuong")
    #expect(session.email == "vuong@example.com")
}

@Test("equatable treats identical results as equal")
func signInResultEquatableEqual() {
    let lhs = AuthSignInResult(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com"
    )
    let rhs = AuthSignInResult(
        userIdentifier: "user-1",
        displayName: "Vuong",
        email: "vuong@example.com"
    )

    #expect(lhs == rhs)
}

@Test("equatable distinguishes by user identifier")
func signInResultEquatableByUserIdentifier() {
    let lhs = AuthSignInResult(userIdentifier: "user-1")
    let rhs = AuthSignInResult(userIdentifier: "user-2")

    #expect(lhs != rhs)
}

@Test("equatable distinguishes by optional fields")
func signInResultEquatableByOptionalFields() {
    let lhs = AuthSignInResult(userIdentifier: "user-1", displayName: "Vuong")
    let rhs = AuthSignInResult(userIdentifier: "user-1", displayName: nil)

    #expect(lhs != rhs)
}
