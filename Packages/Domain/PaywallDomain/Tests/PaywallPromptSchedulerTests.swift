import Foundation
import Testing
@testable import PaywallDomain

struct PaywallPromptSchedulerTests {
    private let now = Date(timeIntervalSince1970: 1_730_000_000)
    private let twoWeeksAgo = Date(timeIntervalSince1970: 1_730_000_000 - 60 * 60 * 24 * 14)
    private let oneWeekAgo = Date(timeIntervalSince1970: 1_730_000_000 - 60 * 60 * 24 * 7)
    private let oneDayAgo = Date(timeIntervalSince1970: 1_730_000_000 - 60 * 60 * 24)

    @Test("free tier with no first launch never prompts")
    func noFirstLaunch() {
        let schedule = PaywallPromptSchedule()
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("paid tier never prompts even after long usage")
    func paidTierNeverPrompts() {
        let schedule = PaywallPromptSchedule(firstLaunchAt: twoWeeksAgo)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .pro, schedule: schedule, now: now) == false)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .family, schedule: schedule, now: now) == false)
    }

    @Test("free tier prompts after 14-day trial period")
    func promptsAfterTrial() {
        let schedule = PaywallPromptSchedule(firstLaunchAt: twoWeeksAgo)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now))
    }

    @Test("free tier does not prompt before trial period ends")
    func noPromptBeforeTrialOver() {
        let schedule = PaywallPromptSchedule(firstLaunchAt: oneWeekAgo)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("cooldown prevents re-prompt within 7 days")
    func cooldownPreventsRepeat() {
        let schedule = PaywallPromptSchedule(
            firstLaunchAt: twoWeeksAgo,
            lastShownAt: oneDayAgo
        )
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("after cooldown the prompt fires again")
    func afterCooldownPromptsAgain() {
        let schedule = PaywallPromptSchedule(
            firstLaunchAt: twoWeeksAgo,
            lastShownAt: Date(timeIntervalSince1970: 1_730_000_000 - 60 * 60 * 24 * 8)
        )
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now))
    }

    @Test("permanent dismissal blocks all future prompts")
    func permanentDismissalBlocks() {
        let schedule = PaywallPromptSchedule(
            firstLaunchAt: twoWeeksAgo,
            lastShownAt: nil,
            hasUserDismissedPermanently: true
        )
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("recordFirstLaunch sets the date only once")
    func recordFirstLaunchIdempotent() {
        var schedule = PaywallPromptSchedule()
        PaywallPromptScheduler.recordFirstLaunchIfNeeded(in: &schedule, now: now)
        #expect(schedule.firstLaunchAt == now)
        let original = schedule.firstLaunchAt
        let later = Date(timeIntervalSince1970: 1_750_000_000)
        PaywallPromptScheduler.recordFirstLaunchIfNeeded(in: &schedule, now: later)
        #expect(schedule.firstLaunchAt == original)
    }
}
