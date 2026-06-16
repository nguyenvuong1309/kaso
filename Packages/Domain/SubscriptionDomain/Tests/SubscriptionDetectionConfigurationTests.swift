import Foundation
import Testing
@testable import SubscriptionDomain

@Test("default configuration uses expected thresholds")
func defaultConfigurationValues() {
    let configuration = SubscriptionDetectionConfiguration()
    #expect(configuration.minimumOccurrences == 2)
    #expect(configuration.amountVarianceTolerance == Decimal(15) / Decimal(100))
    #expect(configuration.minimumIntervalMatchRatio == 0.75)
}

@Test("custom configuration retains provided values")
func customConfigurationValues() {
    let configuration = SubscriptionDetectionConfiguration(
        minimumOccurrences: 4,
        amountVarianceTolerance: Decimal(5) / Decimal(100),
        minimumIntervalMatchRatio: 0.9
    )
    #expect(configuration.minimumOccurrences == 4)
    #expect(configuration.amountVarianceTolerance == Decimal(5) / Decimal(100))
    #expect(configuration.minimumIntervalMatchRatio == 0.9)
}

@Test("configuration is equatable")
func configurationEquatable() {
    #expect(SubscriptionDetectionConfiguration() == SubscriptionDetectionConfiguration())
    #expect(SubscriptionDetectionConfiguration(minimumOccurrences: 3) != SubscriptionDetectionConfiguration())
}
