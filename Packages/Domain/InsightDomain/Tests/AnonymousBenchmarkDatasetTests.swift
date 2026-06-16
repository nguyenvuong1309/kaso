import Foundation
import Testing
import TransactionDomain
@testable import InsightDomain

@Test("benchmark amount scales with representative income via category share")
func benchmarkAmountScalesWithIncome() {
    let profile = AnonymousBenchmarkProfile(
        city: .otherUrban,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .underTenMillion
    )
    // otherUrban cost multiplier 0.84, age/transport behavior 1.08, income 8,000,000, transport share 0.08
    // 8_000_000 * 0.08 * 0.84 * 1.08 = 580_608 -> rounded to nearest 1000 = 581_000
    let amount = AnonymousBenchmarkDataset.benchmarkAmount(category: .transport, profile: profile)
    #expect(amount == 581_000)
}

@Test("benchmark amount is rounded to the nearest thousand")
func benchmarkAmountRoundedToThousand() {
    for category in TransactionCategory.defaultExpenseCategories {
        for city in AnonymousBenchmarkCity.allCases {
            for age in AnonymousBenchmarkAgeGroup.allCases {
                for income in AnonymousBenchmarkIncomeBand.allCases {
                    let profile = AnonymousBenchmarkProfile(city: city, ageGroup: age, incomeBand: income)
                    let amount = AnonymousBenchmarkDataset.benchmarkAmount(category: category, profile: profile)
                    let remainder = NSDecimalNumber(decimal: amount).intValue % 1_000
                    #expect(remainder == 0)
                    #expect(amount > 0)
                }
            }
        }
    }
}

@Test("housing carries the largest share for a fixed profile")
func housingCarriesLargestShare() {
    let profile = AnonymousBenchmarkProfile(
        city: .hoChiMinh,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .twentyToFortyMillion
    )
    let housing = AnonymousBenchmarkDataset.benchmarkAmount(category: .housing, profile: profile)
    let food = AnonymousBenchmarkDataset.benchmarkAmount(category: .food, profile: profile)
    let health = AnonymousBenchmarkDataset.benchmarkAmount(category: .health, profile: profile)
    #expect(housing > food)
    #expect(food > health)
}

@Test("unknown category falls back to the default share")
func unknownCategoryUsesDefaultShare() {
    let profile = AnonymousBenchmarkProfile(
        city: .haNoi,
        ageGroup: .twentyFiveToThirtyFour,
        incomeBand: .tenToTwentyMillion
    )
    // 'other' is not enumerated -> default share 0.06, no behavior multiplier, haNoi cost 1.06
    // 15_000_000 * 0.06 * 1.06 = 954_000
    let other = AnonymousBenchmarkDataset.benchmarkAmount(category: .other, profile: profile)
    #expect(other == 954_000)
}

@Test("age behavior multiplier boosts the matching category")
func ageBehaviorMultiplierBoostsMatchingCategory() {
    let youngProfile = AnonymousBenchmarkProfile(
        city: .daNang,
        ageGroup: .underTwentyFive,
        incomeBand: .tenToTwentyMillion
    )
    let olderProfile = AnonymousBenchmarkProfile(
        city: .daNang,
        ageGroup: .fortyFivePlus,
        incomeBand: .tenToTwentyMillion
    )
    // under-25 gets a 1.12 entertainment boost the 45+ group does not.
    let youngEntertainment = AnonymousBenchmarkDataset.benchmarkAmount(category: .entertainment, profile: youngProfile)
    let olderEntertainment = AnonymousBenchmarkDataset.benchmarkAmount(category: .entertainment, profile: olderProfile)
    #expect(youngEntertainment > olderEntertainment)

    // 45+ gets a 1.25 health boost the under-25 group does not.
    let youngHealth = AnonymousBenchmarkDataset.benchmarkAmount(category: .health, profile: youngProfile)
    let olderHealth = AnonymousBenchmarkDataset.benchmarkAmount(category: .health, profile: olderProfile)
    #expect(olderHealth > youngHealth)
}
