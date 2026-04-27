import Foundation
import PersistenceKit
import Testing
import WellnessDomain

@Test("saves and loads hours of life configuration encrypted")
func savesAndLoadsHoursOfLifeConfigurationEncrypted() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("hours-of-life.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 18_500_000,
        averageMonthlyWorkHours: 168
    )
    let store = EncryptedHoursOfLifeConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 17, count: 32) }
    )

    try await store.save(configuration)

    let loaded = try await store.load()
    let rawData = try Data(contentsOf: fileURL)
    let plainData = try JSONEncoder().encode(configuration)

    #expect(loaded == configuration)
    #expect(rawData != plainData)
}

@Test("returns nil when no configuration is saved")
func returnsNilWhenNoConfigurationIsSaved() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("hours-of-life.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let store = EncryptedHoursOfLifeConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 19, count: 32) }
    )

    #expect(try await store.load() == nil)
}

@Test("overwrites existing configuration when saving again")
func overwritesExistingConfigurationWhenSavingAgain() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("hours-of-life.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let store = EncryptedHoursOfLifeConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 23, count: 32) }
    )

    try await store.save(
        HoursOfLifeConfiguration(monthlyNetIncome: 12_000_000, averageMonthlyWorkHours: 160)
    )
    try await store.save(
        HoursOfLifeConfiguration(monthlyNetIncome: 24_000_000, averageMonthlyWorkHours: 180)
    )

    #expect(
        try await store.load() == HoursOfLifeConfiguration(
            monthlyNetIncome: 24_000_000,
            averageMonthlyWorkHours: 180
        )
    )
}

@Test("clear removes saved configuration")
func clearRemovesSavedConfiguration() async throws {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let fileURL = directoryURL.appendingPathComponent("hours-of-life.kasoenc")
    defer {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    let store = EncryptedHoursOfLifeConfigurationStore(
        fileURL: fileURL,
        keyDataProvider: { Data(repeating: 29, count: 32) }
    )

    try await store.save(
        HoursOfLifeConfiguration(monthlyNetIncome: 12_000_000, averageMonthlyWorkHours: 160)
    )
    try await store.clear()

    #expect(try await store.load() == nil)
}
