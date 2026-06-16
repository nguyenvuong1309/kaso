import Foundation
import Testing
@testable import PaywallDomain

struct SubscriptionTierTests {
    @Test("all cases are present in expected order")
    func allCases() {
        #expect(SubscriptionTier.allCases == [.free, .pro, .family])
    }

    @Test("id equals rawValue")
    func idMatchesRawValue() {
        #expect(SubscriptionTier.free.id == "free")
        #expect(SubscriptionTier.pro.id == "pro")
        #expect(SubscriptionTier.family.id == "family")
    }

    @Test("isPaid is false only for free tier")
    func isPaid() {
        #expect(SubscriptionTier.free.isPaid == false)
        #expect(SubscriptionTier.pro.isPaid)
        #expect(SubscriptionTier.family.isPaid)
    }

    @Test("rank increases free < pro < family")
    func ranks() {
        #expect(SubscriptionTier.free.rank == 0)
        #expect(SubscriptionTier.pro.rank == 1)
        #expect(SubscriptionTier.family.rank == 2)
    }

    @Test("comparable ordering covers all pairs")
    func comparable() {
        #expect(SubscriptionTier.free < .pro)
        #expect(SubscriptionTier.pro < .family)
        #expect(SubscriptionTier.free < .family)
        #expect(SubscriptionTier.family > .pro)
        #expect(SubscriptionTier.pro >= .pro)
        #expect(SubscriptionTier.free <= .free)
        #expect((SubscriptionTier.pro < .free) == false)
    }

    @Test("titleKey follows paywall.tier.<raw>.title convention")
    func titleKey() {
        #expect(SubscriptionTier.free.titleKey == "paywall.tier.free.title")
        #expect(SubscriptionTier.pro.titleKey == "paywall.tier.pro.title")
        #expect(SubscriptionTier.family.titleKey == "paywall.tier.family.title")
    }

    @Test("taglineKey follows paywall.tier.<raw>.tagline convention")
    func taglineKey() {
        #expect(SubscriptionTier.free.taglineKey == "paywall.tier.free.tagline")
        #expect(SubscriptionTier.pro.taglineKey == "paywall.tier.pro.tagline")
        #expect(SubscriptionTier.family.taglineKey == "paywall.tier.family.tagline")
    }

    @Test("Codable round-trips through rawValue for every case")
    func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for tier in SubscriptionTier.allCases {
            let data = try encoder.encode(tier)
            let decoded = try decoder.decode(SubscriptionTier.self, from: data)
            #expect(decoded == tier)
        }
    }

    @Test("encodes to its raw string value")
    func encodesRawString() throws {
        let data = try JSONEncoder().encode(SubscriptionTier.pro)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == "\"pro\"")
    }
}
