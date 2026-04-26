import AuthDomain
import ComposableArchitecture
import Foundation
import Testing
@testable import AuthFeature

@MainActor
@Test("loads saved session on task")
func loadsSavedSessionOnTask() async throws {
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
        displayName: "Vuong",
        signedInAt: date
    )
    let store = TestStore(initialState: AuthFeature.State()) {
        AuthFeature()
    } withDependencies: {
        $0.authSessionRepository.load = { session }
    }

    await store.send(.task) {
        $0.isLoading = true
    }
    await store.receive(.sessionLoaded(session)) {
        $0.isLoading = false
        $0.session = session
    }
}

@MainActor
@Test("saves session after apple sign in")
func savesSessionAfterAppleSignIn() async throws {
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
    let store = TestStore(initialState: AuthFeature.State()) {
        AuthFeature()
    } withDependencies: {
        $0.date.now = date
        $0.authSessionRepository.save = { _ in }
    }

    await store.send(.signInSucceeded(result)) {
        $0.isLoading = true
    }
    await store.receive(.sessionSaved(session)) {
        $0.isLoading = false
        $0.session = session
    }
}

@MainActor
@Test("clears session on sign out")
func clearsSessionOnSignOut() async throws {
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
    let store = TestStore(
        initialState: AuthFeature.State(session: session)
    ) {
        AuthFeature()
    } withDependencies: {
        $0.authSessionRepository.clear = {}
    }

    await store.send(.signOutButtonTapped) {
        $0.isLoading = true
    }
    await store.receive(.signedOut) {
        $0.isLoading = false
        $0.session = nil
    }
}
