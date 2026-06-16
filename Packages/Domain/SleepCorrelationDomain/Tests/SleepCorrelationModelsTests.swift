import Foundation
import Testing
import TransactionDomain
@testable import SleepCorrelationDomain

// MARK: - SleepQuality

@Test("sleep quality is poor below six hours")
func sleepQualityIsPoorBelowSixHours() {
    #expect(SleepQuality(hours: 0) == .poor)
    #expect(SleepQuality(hours: 5.99) == .poor)
}

@Test("sleep quality is fair between six and seven hours")
func sleepQualityIsFairBetweenSixAndSeven() {
    #expect(SleepQuality(hours: 6) == .fair)
    #expect(SleepQuality(hours: 6.5) == .fair)
    #expect(SleepQuality(hours: 6.99) == .fair)
}

@Test("sleep quality is good at seven hours or more")
func sleepQualityIsGoodAtSevenOrMore() {
    #expect(SleepQuality(hours: 7) == .good)
    #expect(SleepQuality(hours: 9.5) == .good)
}

@Test("sleep quality title key follows naming convention")
func sleepQualityTitleKey() {
    #expect(SleepQuality.poor.titleKey == "sleep.quality.poor")
    #expect(SleepQuality.fair.titleKey == "sleep.quality.fair")
    #expect(SleepQuality.good.titleKey == "sleep.quality.good")
}

@Test("sleep quality codable round trip preserves raw value")
func sleepQualityCodableRoundTrip() throws {
    let original = SleepQuality.fair
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SleepQuality.self, from: data)
    #expect(decoded == original)
}

// MARK: - SleepSample

@Test("sleep sample stores date and hours")
func sleepSampleStoresValues() throws {
    let day = try makeDate(year: 2026, month: 1, day: 10)
    let sample = SleepSample(date: day, hours: 7.25)
    #expect(sample.date == day)
    #expect(sample.hours == 7.25)
}

@Test("sleep sample codable round trip")
func sleepSampleCodableRoundTrip() throws {
    let day = try makeDate(year: 2026, month: 2, day: 14)
    let original = SleepSample(date: day, hours: 6.5)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SleepSample.self, from: data)
    #expect(decoded == original)
}

// MARK: - CategorySpending

@Test("category spending stores category and amount")
func categorySpendingStoresValues() {
    let spending = CategorySpending(category: .food, amount: 125_000)
    #expect(spending.category == .food)
    #expect(spending.amount == 125_000)
}

@Test("category spending codable round trip")
func categorySpendingCodableRoundTrip() throws {
    let original = CategorySpending(category: .shopping, amount: 999_000)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(CategorySpending.self, from: data)
    #expect(decoded == original)
}

// MARK: - SleepSpendingDataPoint

@Test("data point derives sleep quality from hours when not provided")
func dataPointDerivesQualityFromHours() throws {
    let day = try makeDate(year: 2026, month: 3, day: 1)
    let point = SleepSpendingDataPoint(
        date: day,
        sleepHours: 5,
        totalSpending: 50_000,
        transactionCount: 2,
        categories: []
    )
    #expect(point.sleepQuality == .poor)
}

@Test("data point uses explicit sleep quality when provided")
func dataPointUsesExplicitQuality() throws {
    let day = try makeDate(year: 2026, month: 3, day: 2)
    let point = SleepSpendingDataPoint(
        date: day,
        sleepHours: 5,
        sleepQuality: .good,
        totalSpending: 50_000,
        transactionCount: 2,
        categories: []
    )
    #expect(point.sleepQuality == .good)
}

@Test("data point id equals its date")
func dataPointIdEqualsDate() throws {
    let day = try makeDate(year: 2026, month: 3, day: 3)
    let point = SleepSpendingDataPoint(
        date: day,
        sleepHours: 8,
        totalSpending: 0,
        transactionCount: 0,
        categories: []
    )
    #expect(point.id == day)
}

@Test("data point codable round trip")
func dataPointCodableRoundTrip() throws {
    let day = try makeDate(year: 2026, month: 3, day: 4)
    let original = SleepSpendingDataPoint(
        date: day,
        sleepHours: 7.5,
        totalSpending: 200_000,
        transactionCount: 3,
        categories: [CategorySpending(category: .food, amount: 200_000)]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SleepSpendingDataPoint.self, from: data)
    #expect(decoded == original)
    #expect(decoded.sleepQuality == .good)
}

// MARK: - SleepCorrelationInsight

@Test("insight exposes default minimum data points and disclaimer")
func insightStaticConstants() {
    #expect(SleepCorrelationInsight.minimumDataPoints == 21)
    #expect(SleepCorrelationInsight.disclaimer.isEmpty == false)
}

@Test("insight init defaults disclaimer to shared constant")
func insightDefaultsDisclaimer() {
    let insight = SleepCorrelationInsight(
        correlationCoefficient: 0.5,
        significance: .strong,
        pattern: .noSignificantPattern,
        dataPointCount: 30,
        insights: ["a"]
    )
    #expect(insight.disclaimer == SleepCorrelationInsight.disclaimer)
}

@Test("insight codable round trip preserves all fields")
func insightCodableRoundTrip() throws {
    let original = SleepCorrelationInsight(
        correlationCoefficient: -0.42,
        significance: .moderate,
        pattern: .lessSleepMoreSpending(avgDiff: 30_000),
        dataPointCount: 25,
        insights: ["one", "two"],
        disclaimer: "custom"
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SleepCorrelationInsight.self, from: data)
    #expect(decoded == original)
}

@Test("insight encodes nil pattern")
func insightCodableNilPattern() throws {
    let original = SleepCorrelationInsight(
        correlationCoefficient: 0,
        significance: .insufficient,
        pattern: nil,
        dataPointCount: 5,
        insights: []
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SleepCorrelationInsight.self, from: data)
    #expect(decoded == original)
    #expect(decoded.pattern == nil)
}

// MARK: - SpendingPattern

@Test("spending pattern equality distinguishes cases and associated values")
func spendingPatternEquality() {
    #expect(SpendingPattern.moreSleepLessSpending(avgDiff: 10) == .moreSleepLessSpending(avgDiff: 10))
    #expect(SpendingPattern.moreSleepLessSpending(avgDiff: 10) != .moreSleepLessSpending(avgDiff: 20))
    #expect(SpendingPattern.lessSleepMoreSpending(avgDiff: 5) != .moreSleepLessSpending(avgDiff: 5))
    #expect(SpendingPattern.noSignificantPattern != .lessSleepMoreImpulse(categories: []))
}

@Test("spending pattern codable round trip for impulse categories")
func spendingPatternCodableImpulse() throws {
    let original = SpendingPattern.lessSleepMoreImpulse(categories: [.shopping, .entertainment])
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SpendingPattern.self, from: data)
    #expect(decoded == original)
}

@Test("spending pattern codable round trip for diff cases")
func spendingPatternCodableDiff() throws {
    for pattern in [
        SpendingPattern.moreSleepLessSpending(avgDiff: 12_345),
        SpendingPattern.lessSleepMoreSpending(avgDiff: 67_890),
        SpendingPattern.noSignificantPattern,
    ] {
        let data = try JSONEncoder().encode(pattern)
        let decoded = try JSONDecoder().decode(SpendingPattern.self, from: data)
        #expect(decoded == pattern)
    }
}

// MARK: - StatisticalSignificance

@Test("statistical significance codable round trip")
func significanceCodableRoundTrip() throws {
    for value in [
        StatisticalSignificance.insufficient,
        .weak,
        .moderate,
        .strong,
    ] {
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(StatisticalSignificance.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - SleepCorrelationPeriod

@Test("period exposes all cases")
func periodAllCases() {
    #expect(SleepCorrelationPeriod.allCases == [.lastThirtyDays, .lastNinetyDays, .all])
}

@Test("period id equals raw value")
func periodIdEqualsRawValue() {
    for period in SleepCorrelationPeriod.allCases {
        #expect(period.id == period.rawValue)
    }
}

@Test("period title key follows naming convention")
func periodTitleKey() {
    #expect(SleepCorrelationPeriod.lastThirtyDays.titleKey == "sleep.period.lastThirtyDays")
    #expect(SleepCorrelationPeriod.lastNinetyDays.titleKey == "sleep.period.lastNinetyDays")
    #expect(SleepCorrelationPeriod.all.titleKey == "sleep.period.all")
}

@Test("period codable round trip")
func periodCodableRoundTrip() throws {
    let data = try JSONEncoder().encode(SleepCorrelationPeriod.lastNinetyDays)
    let decoded = try JSONDecoder().decode(SleepCorrelationPeriod.self, from: data)
    #expect(decoded == .lastNinetyDays)
}

// MARK: - Helpers

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
