import Foundation
import Testing
@testable import PaywallDomain

struct SubscriptionEntitlementTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.calendar = calendar
        components.timeZone = TimeZone(identifier: "UTC")
        return try #require(components.date)
    }

    @Test("default init produces a free entitlement")
    func defaultInit() {
        let entitlement = SubscriptionEntitlement()
        #expect(entitlement.tier == .free)
        #expect(entitlement.activePlanID == nil)
        #expect(entitlement.purchasedAt == nil)
        #expect(entitlement.expiresAt == nil)
        #expect(entitlement.isInTrial == false)
    }

    @Test("static free matches default init")
    func staticFree() {
        #expect(SubscriptionEntitlement.free == SubscriptionEntitlement())
    }

    @Test("custom init stores every field")
    func customInit() throws {
        let purchased = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let expires = try makeDate(year: 2027, month: 1, day: 1, calendar: calendar)
        let entitlement = SubscriptionEntitlement(
            tier: .pro,
            activePlanID: "com.kaso.pro.yearly",
            purchasedAt: purchased,
            expiresAt: expires,
            isInTrial: true
        )
        #expect(entitlement.tier == .pro)
        #expect(entitlement.activePlanID == "com.kaso.pro.yearly")
        #expect(entitlement.purchasedAt == purchased)
        #expect(entitlement.expiresAt == expires)
        #expect(entitlement.isInTrial)
    }

    @Test("Codable round-trips a fully populated entitlement")
    func codableRoundTrip() throws {
        let purchased = try makeDate(year: 2026, month: 3, day: 15, hour: 9, calendar: calendar)
        let expires = try makeDate(year: 2026, month: 4, day: 15, hour: 9, calendar: calendar)
        let original = SubscriptionEntitlement(
            tier: .family,
            activePlanID: "com.kaso.family.monthly",
            purchasedAt: purchased,
            expiresAt: expires,
            isInTrial: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SubscriptionEntitlement.self, from: data)
        #expect(decoded == original)
    }

    @Test("Codable round-trips the free entitlement with nil fields")
    func codableRoundTripFree() throws {
        let data = try JSONEncoder().encode(SubscriptionEntitlement.free)
        let decoded = try JSONDecoder().decode(SubscriptionEntitlement.self, from: data)
        #expect(decoded == .free)
    }

    @Test("entitlements with differing tiers are not equal")
    func equatableTier() {
        let a = SubscriptionEntitlement(tier: .pro)
        let b = SubscriptionEntitlement(tier: .family)
        #expect(a != b)
    }

    @Test("empty repository loads the free entitlement")
    func emptyRepositoryLoad() async throws {
        let loaded = try await SubscriptionEntitlementRepository.empty.load()
        #expect(loaded == .free)
    }

    @Test("empty repository save is a no-op that does not throw")
    func emptyRepositorySave() async throws {
        try await SubscriptionEntitlementRepository.empty.save(SubscriptionEntitlement(tier: .pro))
    }
}
