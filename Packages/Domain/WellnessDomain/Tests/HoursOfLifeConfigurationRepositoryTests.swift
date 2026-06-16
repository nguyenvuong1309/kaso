import Foundation
import Testing
@testable import WellnessDomain

@Test("empty repository loads nil")
func emptyRepositoryLoadsNil() async throws {
    let loaded = try await HoursOfLifeConfigurationRepository.empty.load()
    #expect(loaded == nil)
}

@Test("empty repository save and clear are no-ops that do not throw")
func emptyRepositorySaveAndClearAreNoOps() async throws {
    let repository = HoursOfLifeConfigurationRepository.empty
    try await repository.save(
        HoursOfLifeConfiguration(monthlyNetIncome: 20_000_000, averageMonthlyWorkHours: 160)
    )
    try await repository.clear()

    let loaded = try await repository.load()
    #expect(loaded == nil)
}

@Test("custom repository round-trips through injected closures")
func customRepositoryRoundTripsThroughInjectedClosures() async throws {
    let storage = ConfigurationStorage()
    let repository = HoursOfLifeConfigurationRepository(
        load: { await storage.value },
        save: { await storage.set($0) },
        clear: { await storage.set(nil) }
    )

    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 18_000_000,
        averageMonthlyWorkHours: 168
    )
    try await repository.save(configuration)
    #expect(try await repository.load() == configuration)

    try await repository.clear()
    #expect(try await repository.load() == nil)
}

private actor ConfigurationStorage {
    private(set) var value: HoursOfLifeConfiguration?

    func set(_ value: HoursOfLifeConfiguration?) {
        self.value = value
    }
}
