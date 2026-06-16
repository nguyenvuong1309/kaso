import Foundation
import Testing
@testable import InsightDomain

@Test("trend round-trips through Codable")
func trendRoundTrips() throws {
    for trend in [SpendingComparisonTrend.increased, .decreased, .flat] {
        let data = try JSONEncoder().encode(trend)
        let decoded = try JSONDecoder().decode(SpendingComparisonTrend.self, from: data)
        #expect(decoded == trend)
    }
}

@Test("period comparison stores nil percentage change")
func periodComparisonStoresNilPercentage() {
    let comparison = SpendingPeriodComparison(
        currentExpense: 1_000_000,
        previousExpense: 0,
        delta: 1_000_000,
        percentageChange: nil,
        trend: .increased
    )
    #expect(comparison.currentExpense == 1_000_000)
    #expect(comparison.previousExpense == 0)
    #expect(comparison.delta == 1_000_000)
    #expect(comparison.percentageChange == nil)
    #expect(comparison.trend == .increased)
}

@Test("report bundles month and year-to-date comparisons")
func reportBundlesComparisons() {
    let month = SpendingPeriodComparison(
        currentExpense: 3_000_000,
        previousExpense: 2_000_000,
        delta: 1_000_000,
        percentageChange: 0.5,
        trend: .increased
    )
    let yearToDate = SpendingPeriodComparison(
        currentExpense: 12_000_000,
        previousExpense: 12_000_000,
        delta: 0,
        percentageChange: 0,
        trend: .flat
    )
    let report = SpendingComparisonReport(month: month, yearToDate: yearToDate)
    #expect(report.month == month)
    #expect(report.yearToDate == yearToDate)
    #expect(report.yearToDate.trend == .flat)
}
