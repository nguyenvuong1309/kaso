import Foundation
import Testing
@testable import AppearanceDomain

private struct AppearanceTestError: Error, Equatable {}

@Test("empty repository load returns the default settings")
func emptyRepositoryLoadReturnsDefault() async throws {
    let loaded = try await AppearanceSettingsRepository.empty.load()
    #expect(loaded == .defaultValue)
}

@Test("empty repository save accepts any value without throwing")
func emptyRepositorySaveIsNoOp() async throws {
    try await AppearanceSettingsRepository.empty.save(
        AppearanceSettings(mode: .dark, accentColor: .pink)
    )
}

@Test("repository init wires through provided load closure")
func repositoryInitLoadClosure() async throws {
    let expected = AppearanceSettings(mode: .light, accentColor: .blue)
    let repository = AppearanceSettingsRepository(
        load: { expected },
        save: { _ in }
    )
    let loaded = try await repository.load()
    #expect(loaded == expected)
}

@Test("repository save closure receives the exact settings passed in")
func repositorySaveClosureReceivesSettings() async throws {
    let recorder = SettingsRecorder()
    let repository = AppearanceSettingsRepository(
        load: { .defaultValue },
        save: { await recorder.record($0) }
    )
    let input = AppearanceSettings(mode: .dark, accentColor: .orange)
    try await repository.save(input)
    #expect(await recorder.recorded == input)
}

@Test("repository load propagates thrown errors")
func repositoryLoadPropagatesError() async {
    let repository = AppearanceSettingsRepository(
        load: { throw AppearanceTestError() },
        save: { _ in }
    )
    await #expect(throws: AppearanceTestError.self) {
        _ = try await repository.load()
    }
}

@Test("repository save propagates thrown errors")
func repositorySavePropagatesError() async {
    let repository = AppearanceSettingsRepository(
        load: { .defaultValue },
        save: { _ in throw AppearanceTestError() }
    )
    await #expect(throws: AppearanceTestError.self) {
        try await repository.save(.defaultValue)
    }
}

/// Actor recorder so the save closure can capture values without data races.
private actor SettingsRecorder {
    private(set) var recorded: AppearanceSettings?

    func record(_ settings: AppearanceSettings) {
        recorded = settings
    }
}
