import Foundation
import Testing
@testable import PaywallDomain

struct SubscriptionFeatureTests {
    @Test("free-tier feature flags require the free tier")
    func freeFeatures() {
        #expect(SubscriptionFeatureFlag.csvExport.minimumTier == .free)
        #expect(SubscriptionFeatureFlag.widgets.minimumTier == .free)
    }

    @Test("pro-tier feature flags require the pro tier")
    func proFeatures() {
        let proFlags: [SubscriptionFeatureFlag] = [
            .unlimitedHistory, .ocrReceipt, .bankStatementImport, .voiceEntry,
            .subscriptionTracker, .aiInsights, .spendingForecast, .savingsGoals,
            .advancedReports, .iCloudSync, .appleWatch,
        ]
        for flag in proFlags {
            #expect(flag.minimumTier == .pro)
        }
    }

    @Test("family-tier feature flags require the family tier")
    func familyFeatures() {
        #expect(SubscriptionFeatureFlag.familySharing.minimumTier == .family)
        #expect(SubscriptionFeatureFlag.familyCompatibility.minimumTier == .family)
    }

    @Test("every flag has a minimum tier mapped")
    func everyFlagMapped() {
        for flag in SubscriptionFeatureFlag.allCases {
            let tier = flag.minimumTier
            #expect(SubscriptionTier.allCases.contains(tier))
        }
    }

    @Test("titleKey follows paywall.feature.<raw>.title convention")
    func titleKey() {
        #expect(SubscriptionFeatureFlag.ocrReceipt.titleKey == "paywall.feature.ocrReceipt.title")
        #expect(SubscriptionFeatureFlag.familySharing.titleKey == "paywall.feature.familySharing.title")
    }

    @Test("unlocks is true when tier rank >= feature minimum tier")
    func unlocksMonotonic() {
        for flag in SubscriptionFeatureFlag.allCases {
            for tier in SubscriptionTier.allCases {
                let expected = tier >= flag.minimumTier
                #expect(tier.unlocks(flag) == expected)
            }
        }
    }

    @Test("free tier unlocks exactly the free feature set")
    func freeUnlockedSet() {
        let unlocked = SubscriptionTier.free.unlockedFeatures
        #expect(unlocked == [.csvExport, .widgets])
    }

    @Test("pro tier unlocks all non-family features")
    func proUnlockedSet() {
        let unlocked = SubscriptionTier.pro.unlockedFeatures
        #expect(unlocked.contains(.familySharing) == false)
        #expect(unlocked.contains(.familyCompatibility) == false)
        let familyOnly: Set<SubscriptionFeatureFlag> = [.familySharing, .familyCompatibility]
        let expected = Set(SubscriptionFeatureFlag.allCases).subtracting(familyOnly)
        #expect(unlocked == expected)
    }

    @Test("family tier unlocks every feature flag")
    func familyUnlockedSet() {
        #expect(SubscriptionTier.family.unlockedFeatures == Set(SubscriptionFeatureFlag.allCases))
    }

    @Test("flag raw values are stable identifiers")
    func rawValues() {
        #expect(SubscriptionFeatureFlag.aiInsights.rawValue == "aiInsights")
        #expect(SubscriptionFeatureFlag.iCloudSync.rawValue == "iCloudSync")
    }
}
