import Foundation
import Testing
@testable import RoundUpDomain

@Test("rule default init is disabled with tenThousand step and no cap or goal")
func ruleDefaultInit() {
    let rule = RoundUpRule()
    #expect(rule.isEnabled == false)
    #expect(rule.step == .tenThousand)
    #expect(rule.maxContributionPerTransaction == nil)
    #expect(rule.linkedSavingGoalID == nil)
}

@Test("rule custom init stores all properties")
func ruleCustomInit() {
    let goalID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
    let rule = RoundUpRule(
        isEnabled: true,
        step: .fiftyThousand,
        maxContributionPerTransaction: 20_000,
        linkedSavingGoalID: goalID
    )

    #expect(rule.isEnabled)
    #expect(rule.step == .fiftyThousand)
    #expect(rule.maxContributionPerTransaction == 20_000)
    #expect(rule.linkedSavingGoalID == goalID)
}

@Test("rule equatable distinguishes differing fields")
func ruleEquatable() {
    let base = RoundUpRule(isEnabled: true, step: .tenThousand)
    #expect(base == RoundUpRule(isEnabled: true, step: .tenThousand))
    #expect(base != RoundUpRule(isEnabled: false, step: .tenThousand))
    #expect(base != RoundUpRule(isEnabled: true, step: .fiveThousand))
    #expect(base != RoundUpRule(isEnabled: true, step: .tenThousand, maxContributionPerTransaction: 1))
}

@Test("rule Codable round-trips with all fields populated")
func ruleCodableRoundTripFull() throws {
    let rule = RoundUpRule(
        isEnabled: true,
        step: .fiveThousand,
        maxContributionPerTransaction: 15_000,
        linkedSavingGoalID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")
    )

    let data = try JSONEncoder().encode(rule)
    let decoded = try JSONDecoder().decode(RoundUpRule.self, from: data)
    #expect(decoded == rule)
}

@Test("rule Codable round-trips with nil optionals")
func ruleCodableRoundTripNilOptionals() throws {
    let rule = RoundUpRule()
    let data = try JSONEncoder().encode(rule)
    let decoded = try JSONDecoder().decode(RoundUpRule.self, from: data)
    #expect(decoded == rule)
    #expect(decoded.maxContributionPerTransaction == nil)
    #expect(decoded.linkedSavingGoalID == nil)
}
