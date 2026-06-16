import Foundation
import Testing
@testable import CloudSyncDomain

struct CloudSyncPreferencesTests {
    // MARK: - init defaults

    @Test("default init disables sync, has no last sync, and syncs the four kinds")
    func initDefaults() {
        let prefs = CloudSyncPreferences()
        #expect(prefs.isEnabled == false)
        #expect(prefs.lastSyncedAt == nil)
        #expect(prefs.syncedKinds == [.transaction, .budget, .category, .savingGoal])
    }

    @Test("static default matches the default initializer")
    func staticDefault() {
        #expect(CloudSyncPreferences.default == CloudSyncPreferences())
    }

    @Test("custom init keeps provided values")
    func customInit() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try makeDate(year: 2026, month: 5, day: 20, calendar: calendar)
        let prefs = CloudSyncPreferences(
            isEnabled: true,
            lastSyncedAt: date,
            syncedKinds: [.transaction]
        )
        #expect(prefs.isEnabled)
        #expect(prefs.lastSyncedAt == date)
        #expect(prefs.syncedKinds == [.transaction])
    }

    @Test("syncedKinds may be empty")
    func emptySyncedKinds() {
        let prefs = CloudSyncPreferences(syncedKinds: [])
        #expect(prefs.syncedKinds.isEmpty)
    }

    // MARK: - Equatable

    @Test("preferences with identical fields are equal")
    func equatableEqual() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try makeDate(year: 2026, month: 5, day: 20, calendar: calendar)
        let a = CloudSyncPreferences(isEnabled: true, lastSyncedAt: date, syncedKinds: [.budget])
        let b = CloudSyncPreferences(isEnabled: true, lastSyncedAt: date, syncedKinds: [.budget])
        #expect(a == b)
    }

    @Test("preferences differing in enabled flag are not equal")
    func equatableEnabledDiffers() {
        let a = CloudSyncPreferences(isEnabled: true)
        let b = CloudSyncPreferences(isEnabled: false)
        #expect(a != b)
    }

    @Test("preferences differing in synced kinds are not equal")
    func equatableKindsDiffer() {
        let a = CloudSyncPreferences(syncedKinds: [.transaction])
        let b = CloudSyncPreferences(syncedKinds: [.budget])
        #expect(a != b)
    }

    // MARK: - Codable

    @Test("preferences round-trip through Codable with nil last sync")
    func codableRoundTripNilDate() throws {
        let prefs = CloudSyncPreferences(isEnabled: true, lastSyncedAt: nil, syncedKinds: [.category, .savingGoal])
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(CloudSyncPreferences.self, from: data)
        #expect(decoded == prefs)
    }

    @Test("preferences round-trip through Codable with a last sync date")
    func codableRoundTripWithDate() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let prefs = CloudSyncPreferences(isEnabled: false, lastSyncedAt: date, syncedKinds: [.transaction])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(prefs)
        let decoded = try decoder.decode(CloudSyncPreferences.self, from: data)
        #expect(decoded == prefs)
    }

    // MARK: - Repository

    @Test("empty repository loads default and accepts saves silently")
    func emptyRepository() async throws {
        let repo = CloudSyncPreferencesRepository.empty
        let loaded = try await repo.load()
        #expect(loaded == .default)
        try await repo.save(CloudSyncPreferences(isEnabled: true))
    }

    @Test("preview repository loads an enabled preference set")
    func previewRepository() async throws {
        let repo = CloudSyncPreferencesRepository.preview
        let loaded = try await repo.load()
        #expect(loaded.isEnabled)
        #expect(loaded.lastSyncedAt != nil)
    }

    @Test("custom repository closures route load and save")
    func customRepository() async throws {
        let stored = CloudSyncPreferences(isEnabled: true, syncedKinds: [.budget])
        let captured = SavedBox()
        let repo = CloudSyncPreferencesRepository(
            load: { stored },
            save: { await captured.set($0) }
        )
        let loaded = try await repo.load()
        #expect(loaded == stored)
        let toSave = CloudSyncPreferences(isEnabled: false, syncedKinds: [.category])
        try await repo.save(toSave)
        let saved = await captured.value
        #expect(saved == toSave)
    }
}

private actor SavedBox {
    private(set) var value: CloudSyncPreferences?
    func set(_ value: CloudSyncPreferences) { self.value = value }
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
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
