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

private struct AuthSessionRepositoryError: Error, Equatable {}

@Test("empty repository load returns nil")
func emptyRepositoryLoadReturnsNil() async throws {
    let repository = AuthSessionRepository.empty
    let loaded = try await repository.load()

    #expect(loaded == nil)
}

@Test("empty repository save and clear do not throw")
func emptyRepositorySaveAndClearNoThrow() async throws {
    let date = try makeDate(year: 2026, month: 3, day: 10)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)
    let repository = AuthSessionRepository.empty

    try await repository.save(session)
    try await repository.clear()
}

@Test("custom load closure returns the configured session")
func customLoadReturnsSession() async throws {
    let date = try makeDate(year: 2026, month: 3, day: 10, hour: 12)
    let stored = AuthSession(
        userIdentifier: "user-1",
        displayName: "Vuong",
        signedInAt: date
    )
    let repository = AuthSessionRepository(
        load: { stored },
        save: { _ in },
        clear: {}
    )

    let loaded = try await repository.load()

    #expect(loaded == stored)
}

@Test("save closure receives the session and load reflects it")
func saveAndLoadReflectsSession() async throws {
    let date = try makeDate(year: 2026, month: 3, day: 10, hour: 12)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)
    let box = SessionBox()
    let repository = AuthSessionRepository(
        load: { await box.value },
        save: { await box.set($0) },
        clear: { await box.set(nil) }
    )

    try await repository.save(session)
    let loaded = try await repository.load()

    #expect(loaded == session)
}

@Test("clear closure removes the stored session")
func clearRemovesSession() async throws {
    let date = try makeDate(year: 2026, month: 3, day: 10, hour: 12)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)
    let box = SessionBox()
    let repository = AuthSessionRepository(
        load: { await box.value },
        save: { await box.set($0) },
        clear: { await box.set(nil) }
    )

    try await repository.save(session)
    try await repository.clear()
    let loaded = try await repository.load()

    #expect(loaded == nil)
}

@Test("load propagates thrown errors")
func loadPropagatesError() async {
    let repository = AuthSessionRepository(
        load: { throw AuthSessionRepositoryError() },
        save: { _ in },
        clear: {}
    )

    await #expect(throws: AuthSessionRepositoryError.self) {
        _ = try await repository.load()
    }
}

@Test("save propagates thrown errors")
func savePropagatesError() async throws {
    let date = try makeDate(year: 2026, month: 3, day: 10)
    let session = AuthSession(userIdentifier: "user-1", signedInAt: date)
    let repository = AuthSessionRepository(
        load: { nil },
        save: { _ in throw AuthSessionRepositoryError() },
        clear: {}
    )

    await #expect(throws: AuthSessionRepositoryError.self) {
        try await repository.save(session)
    }
}

@Test("clear propagates thrown errors")
func clearPropagatesError() async {
    let repository = AuthSessionRepository(
        load: { nil },
        save: { _ in },
        clear: { throw AuthSessionRepositoryError() }
    )

    await #expect(throws: AuthSessionRepositoryError.self) {
        try await repository.clear()
    }
}

private actor SessionBox {
    private(set) var value: AuthSession?

    func set(_ session: AuthSession?) {
        value = session
    }
}
