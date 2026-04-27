import ComposableArchitecture
import WellnessDomain

private enum HoursOfLifeConfigurationRepositoryKey: DependencyKey {
    static let liveValue = HoursOfLifeConfigurationRepository.empty
    static let previewValue = HoursOfLifeConfigurationRepository.preview
    static let testValue = HoursOfLifeConfigurationRepository.empty
}

public extension HoursOfLifeConfigurationRepository {
    static let preview = HoursOfLifeConfigurationRepository(
        load: {
            HoursOfLifeConfiguration(
                monthlyNetIncome: 18_000_000,
                averageMonthlyWorkHours: 160
            )
        },
        save: { _ in },
        clear: {}
    )
}

public extension DependencyValues {
    var hoursOfLifeConfigurationRepository: HoursOfLifeConfigurationRepository {
        get { self[HoursOfLifeConfigurationRepositoryKey.self] }
        set { self[HoursOfLifeConfigurationRepositoryKey.self] = newValue }
    }
}
