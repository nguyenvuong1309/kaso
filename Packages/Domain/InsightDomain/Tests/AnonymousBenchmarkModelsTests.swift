import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("benchmark enums expose stable raw-value identifiers and title keys")
func benchmarkEnumsExposeStableIdentifiers() {
    #expect(AnonymousBenchmarkCity.hoChiMinh.id == "hoChiMinh")
    #expect(AnonymousBenchmarkCity.hoChiMinh.titleKey == "benchmark.city.hoChiMinh")
    #expect(AnonymousBenchmarkAgeGroup.fortyFivePlus.id == "fortyFivePlus")
    #expect(AnonymousBenchmarkAgeGroup.fortyFivePlus.titleKey == "benchmark.age.fortyFivePlus")
    #expect(AnonymousBenchmarkIncomeBand.overFortyMillion.id == "overFortyMillion")
    #expect(AnonymousBenchmarkIncomeBand.overFortyMillion.titleKey == "benchmark.income.overFortyMillion")
    #expect(AnonymousBenchmarkStatus.aboveMedian.titleKey == "benchmark.status.aboveMedian")
}

@Test("benchmark enums enumerate all cases")
func benchmarkEnumsEnumerateAllCases() {
    #expect(AnonymousBenchmarkCity.allCases.count == 4)
    #expect(AnonymousBenchmarkAgeGroup.allCases.count == 4)
    #expect(AnonymousBenchmarkIncomeBand.allCases.count == 4)
}

@Test("income band inference uses boundary values inclusively at the lower edge")
func incomeBandInferenceBoundaries() {
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: nil) == .tenToTwentyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 0) == .underTenMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 9_999_999) == .underTenMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 10_000_000) == .tenToTwentyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 19_999_999) == .tenToTwentyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 20_000_000) == .twentyToFortyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 39_999_999) == .twentyToFortyMillion)
    #expect(AnonymousBenchmarkIncomeBand.inferred(from: 40_000_000) == .overFortyMillion)
}

@Test("profile uses documented default member values")
func profileUsesDefaultMemberValues() {
    let profile = AnonymousBenchmarkProfile()
    #expect(profile.city == .hoChiMinh)
    #expect(profile.ageGroup == .twentyFiveToThirtyFour)
    #expect(profile.incomeBand == .tenToTwentyMillion)
}

@Test("profile round-trips through Codable")
func profileRoundTripsThroughCodable() throws {
    let profile = AnonymousBenchmarkProfile(
        city: .daNang,
        ageGroup: .underTwentyFive,
        incomeBand: .overFortyMillion
    )
    let data = try JSONEncoder().encode(profile)
    let decoded = try JSONDecoder().decode(AnonymousBenchmarkProfile.self, from: data)
    #expect(decoded == profile)
}

@Test("category comparison id mirrors the underlying category id")
func categoryComparisonIdMirrorsCategory() {
    let comparison = AnonymousBenchmarkCategoryComparison(
        category: .food,
        userAmount: 1_000_000,
        benchmarkAmount: 800_000,
        differenceAmount: 200_000,
        differenceRatio: Decimal(string: "0.25") ?? 0,
        status: .aboveMedian,
        peerPercentile: 60
    )
    #expect(comparison.id == TransactionCategory.food.id)
}

@Test("top comparisons drop empty entries and sort by absolute difference then id")
func topComparisonsSortByAbsoluteDifference() {
    let report = AnonymousBenchmarkReport(
        profile: AnonymousBenchmarkProfile(),
        totalUserExpense: 0,
        totalBenchmarkExpense: 0,
        overallStatus: .nearMedian,
        overallPeerPercentile: 50,
        comparisons: [
            makeComparison(category: .food, difference: 300_000, user: 300_000, benchmark: 0),
            makeComparison(category: .transport, difference: -500_000, user: 0, benchmark: 500_000),
            makeComparison(category: .housing, difference: 0, user: 0, benchmark: 0),
            makeComparison(category: .shopping, difference: 300_000, user: 300_000, benchmark: 0),
        ]
    )

    let top = report.topComparisons
    #expect(top.map { $0.category.id } == ["transport", "food", "shopping"])
    #expect(top.contains { $0.category == .housing } == false)
}

private func makeComparison(
    category: TransactionCategory,
    difference: Decimal,
    user: Decimal,
    benchmark: Decimal
) -> AnonymousBenchmarkCategoryComparison {
    AnonymousBenchmarkCategoryComparison(
        category: category,
        userAmount: user,
        benchmarkAmount: benchmark,
        differenceAmount: difference,
        differenceRatio: 0,
        status: .nearMedian,
        peerPercentile: 50
    )
}
