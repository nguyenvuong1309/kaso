import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct MoneyPersonalityTraitTests {
    @Test("stores value within range unchanged")
    func valueWithinRange() {
        let trait = MoneyPersonalityTrait(id: "planning", labelKey: "key", value: 0.42)
        #expect(trait.id == "planning")
        #expect(trait.labelKey == "key")
        #expect(trait.value == 0.42)
    }

    @Test("clamps value above 1 down to 1")
    func clampsUpperBound() {
        let trait = MoneyPersonalityTrait(id: "x", labelKey: "k", value: 1.5)
        #expect(trait.value == 1.0)
    }

    @Test("clamps negative value up to 0")
    func clampsLowerBound() {
        let trait = MoneyPersonalityTrait(id: "x", labelKey: "k", value: -0.3)
        #expect(trait.value == 0.0)
    }

    @Test("accepts exact boundary values 0 and 1")
    func boundaryValues() {
        #expect(MoneyPersonalityTrait(id: "a", labelKey: "k", value: 0).value == 0)
        #expect(MoneyPersonalityTrait(id: "b", labelKey: "k", value: 1).value == 1)
    }

    @Test("equatable compares all stored fields")
    func equatable() {
        let a = MoneyPersonalityTrait(id: "x", labelKey: "k", value: 0.5)
        let b = MoneyPersonalityTrait(id: "x", labelKey: "k", value: 0.5)
        let c = MoneyPersonalityTrait(id: "y", labelKey: "k", value: 0.5)
        #expect(a == b)
        #expect(a != c)
    }
}

struct MoneyPersonalityProfileTests {
    @Test("confidence returns the score for the chosen type")
    func confidenceReturnsTypeScore() throws {
        let calendar = Calendar(identifier: .gregorian)
        let analyzedAt = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
        let profile = MoneyPersonalityProfile(
            type: .foodie,
            typeScores: [.foodie: 0.82, .planner: 0.31],
            traits: [],
            analyzedTransactionCount: 40,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
        #expect(profile.confidence == 0.82)
    }

    @Test("confidence falls back to 0 when chosen type has no score")
    func confidenceMissingScore() throws {
        let calendar = Calendar(identifier: .gregorian)
        let analyzedAt = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
        let profile = MoneyPersonalityProfile(
            type: .impulsive,
            typeScores: [.planner: 0.5],
            traits: [],
            analyzedTransactionCount: 40,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
        #expect(profile.confidence == 0)
    }

    @Test("init stores all properties verbatim")
    func initStoresProperties() throws {
        let calendar = Calendar(identifier: .gregorian)
        let analyzedAt = try makeDate(year: 2026, month: 5, day: 20, calendar: calendar)
        let traits = [MoneyPersonalityTrait(id: "planning", labelKey: "k", value: 0.5)]
        let profile = MoneyPersonalityProfile(
            type: .minimalist,
            typeScores: [.minimalist: 0.9],
            traits: traits,
            analyzedTransactionCount: 55,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
        #expect(profile.type == .minimalist)
        #expect(profile.typeScores == [.minimalist: 0.9])
        #expect(profile.traits == traits)
        #expect(profile.analyzedTransactionCount == 55)
        #expect(profile.analyzedAt == analyzedAt)
        #expect(profile.isSufficient)
    }

    @Test("insufficientPlaceholder has empty scores and is not sufficient")
    func insufficientPlaceholder() {
        let placeholder = MoneyPersonalityProfile.insufficientPlaceholder
        #expect(placeholder.type == .planner)
        #expect(placeholder.typeScores.isEmpty)
        #expect(placeholder.traits.isEmpty)
        #expect(placeholder.analyzedTransactionCount == 0)
        #expect(placeholder.isSufficient == false)
        #expect(placeholder.confidence == 0)
        #expect(placeholder.analyzedAt == Date(timeIntervalSinceReferenceDate: 0))
    }

    @Test("profiles with identical fields are equatable")
    func equatable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let analyzedAt = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
        let a = MoneyPersonalityProfile(
            type: .planner,
            typeScores: [.planner: 0.7],
            traits: [],
            analyzedTransactionCount: 30,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
        let b = MoneyPersonalityProfile(
            type: .planner,
            typeScores: [.planner: 0.7],
            traits: [],
            analyzedTransactionCount: 30,
            analyzedAt: analyzedAt,
            isSufficient: true
        )
        #expect(a == b)
        #expect(a != MoneyPersonalityProfile.insufficientPlaceholder)
    }
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
