import Foundation
import Testing
@testable import CoolingOffDomain

@Test("policy init sorts thresholds ascending by minAmount")
func policySortsThresholds() {
    let policy = CoolingOffPolicy(
        thresholds: [
            .init(minAmount: 5_000_000, period: .oneWeek),
            .init(minAmount: 500_000, period: .oneDay),
            .init(minAmount: 2_000_000, period: .threeDays),
        ]
    )
    #expect(policy.thresholds.map(\.minAmount) == [500_000, 2_000_000, 5_000_000])
}

@Test("policy default period defaults to oneDay")
func policyDefaultPeriodDefault() {
    let policy = CoolingOffPolicy(thresholds: [])
    #expect(policy.defaultPeriod == .oneDay)
}

@Test("policy uses custom default period")
func policyCustomDefaultPeriod() {
    let policy = CoolingOffPolicy(thresholds: [], defaultPeriod: .twoWeeks)
    #expect(policy.defaultPeriod == .twoWeeks)
}

@Test("policy with no thresholds returns default period for any amount")
func policyEmptyThresholds() {
    let policy = CoolingOffPolicy(thresholds: [], defaultPeriod: .oneWeek)
    #expect(policy.suggestedPeriod(for: 0) == .oneWeek)
    #expect(policy.suggestedPeriod(for: 100_000_000) == .oneWeek)
}

@Test("policy suggests default period below the lowest threshold")
func policyBelowLowestThreshold() {
    let policy = CoolingOffPolicy.default
    #expect(policy.suggestedPeriod(for: 0) == .oneDay)
    #expect(policy.suggestedPeriod(for: 499_999) == .oneDay)
}

@Test("policy boundary amounts pick the matching threshold inclusively")
func policyBoundaryAmounts() {
    let policy = CoolingOffPolicy.default
    #expect(policy.suggestedPeriod(for: 2_000_000) == .threeDays)
    #expect(policy.suggestedPeriod(for: 5_000_000) == .oneWeek)
    #expect(policy.suggestedPeriod(for: 20_000_000) == .twoWeeks)
}

@Test("policy above highest threshold keeps the highest period")
func policyAboveHighestThreshold() {
    let policy = CoolingOffPolicy.default
    #expect(policy.suggestedPeriod(for: 999_999_999) == .twoWeeks)
}

@Test("policy default exposes four thresholds")
func policyDefaultThresholds() {
    #expect(CoolingOffPolicy.default.thresholds.count == 4)
    #expect(CoolingOffPolicy.default.defaultPeriod == .oneDay)
}

@Test("policy round-trips through Codable")
func policyCodableRoundTrip() throws {
    let policy = CoolingOffPolicy.default
    let data = try JSONEncoder().encode(policy)
    let decoded = try JSONDecoder().decode(CoolingOffPolicy.self, from: data)
    #expect(decoded == policy)
}

@Test("threshold round-trips through Codable")
func thresholdCodableRoundTrip() throws {
    let threshold = CoolingOffPolicy.Threshold(minAmount: 1_234_567, period: .oneWeek)
    let data = try JSONEncoder().encode(threshold)
    let decoded = try JSONDecoder().decode(CoolingOffPolicy.Threshold.self, from: data)
    #expect(decoded == threshold)
}

@Test("policy equality compares thresholds and default period")
func policyEquality() {
    let a = CoolingOffPolicy(thresholds: [.init(minAmount: 100, period: .oneDay)], defaultPeriod: .oneDay)
    let b = CoolingOffPolicy(thresholds: [.init(minAmount: 100, period: .oneDay)], defaultPeriod: .oneDay)
    let c = CoolingOffPolicy(thresholds: [.init(minAmount: 100, period: .oneDay)], defaultPeriod: .twoWeeks)
    #expect(a == b)
    #expect(a != c)
}
