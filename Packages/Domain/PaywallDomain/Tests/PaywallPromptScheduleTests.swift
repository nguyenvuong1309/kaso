import Foundation
import Testing
@testable import PaywallDomain

/// Covers `PaywallPromptSchedule` value semantics, the schedule repository, the
/// `recordPromptShown` mutator, and exact trial/cooldown boundary behaviour not
/// already exercised by `PaywallPromptSchedulerTests`.
struct PaywallPromptScheduleTests {
    private let now = Date(timeIntervalSince1970: 1_730_000_000)

    private func ago(days: Double) -> Date {
        Date(timeIntervalSince1970: 1_730_000_000 - days * 60 * 60 * 24)
    }

    // MARK: - PaywallPromptSchedule value type

    @Test("default schedule has empty fields")
    func defaultSchedule() {
        let schedule = PaywallPromptSchedule()
        #expect(schedule.firstLaunchAt == nil)
        #expect(schedule.lastShownAt == nil)
        #expect(schedule.hasUserDismissedPermanently == false)
    }

    @Test("static initial matches default init")
    func staticInitial() {
        #expect(PaywallPromptSchedule.initial == PaywallPromptSchedule())
    }

    @Test("schedule Codable round-trips")
    func codableRoundTrip() throws {
        let original = PaywallPromptSchedule(
            firstLaunchAt: now,
            lastShownAt: ago(days: 3),
            hasUserDismissedPermanently: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PaywallPromptSchedule.self, from: data)
        #expect(decoded == original)
    }

    @Test("schedules differing in any field are not equal")
    func equatable() {
        let base = PaywallPromptSchedule(firstLaunchAt: now)
        #expect(base != PaywallPromptSchedule(firstLaunchAt: ago(days: 1)))
        #expect(base != PaywallPromptSchedule(firstLaunchAt: now, lastShownAt: now))
        #expect(base != PaywallPromptSchedule(firstLaunchAt: now, hasUserDismissedPermanently: true))
    }

    // MARK: - Repository

    @Test("empty repository loads the initial schedule")
    func emptyRepositoryLoad() async throws {
        let loaded = try await PaywallPromptScheduleRepository.empty.load()
        #expect(loaded == .initial)
    }

    @Test("empty repository save is a no-op that does not throw")
    func emptyRepositorySave() async throws {
        try await PaywallPromptScheduleRepository.empty.save(PaywallPromptSchedule(firstLaunchAt: now))
    }

    // MARK: - recordPromptShown

    @Test("recordPromptShown sets lastShownAt to now")
    func recordPromptShown() {
        var schedule = PaywallPromptSchedule(firstLaunchAt: ago(days: 14))
        PaywallPromptScheduler.recordPromptShown(in: &schedule, now: now)
        #expect(schedule.lastShownAt == now)
    }

    @Test("recordPromptShown overwrites a prior lastShownAt")
    func recordPromptShownOverwrites() {
        var schedule = PaywallPromptSchedule(firstLaunchAt: ago(days: 30), lastShownAt: ago(days: 10))
        PaywallPromptScheduler.recordPromptShown(in: &schedule, now: now)
        #expect(schedule.lastShownAt == now)
    }

    // MARK: - Boundary behaviour

    @Test("prompt fires exactly at the trial-period boundary")
    func trialBoundaryInclusive() {
        let firstLaunch = Date(timeIntervalSince1970: now.timeIntervalSince1970 - PaywallPromptScheduler.trialPeriod)
        let schedule = PaywallPromptSchedule(firstLaunchAt: firstLaunch)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now))
    }

    @Test("prompt does not fire one second before the trial boundary")
    func justBeforeTrialBoundary() {
        let firstLaunch = Date(
            timeIntervalSince1970: now.timeIntervalSince1970 - PaywallPromptScheduler.trialPeriod + 1
        )
        let schedule = PaywallPromptSchedule(firstLaunchAt: firstLaunch)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("prompt is suppressed exactly at the cooldown boundary")
    func cooldownBoundaryInclusive() {
        let lastShown = Date(timeIntervalSince1970: now.timeIntervalSince1970 - PaywallPromptScheduler.cooldown)
        let schedule = PaywallPromptSchedule(firstLaunchAt: ago(days: 60), lastShownAt: lastShown)
        // now - lastShown == cooldown, which is NOT < cooldown, so prompt fires.
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now))
    }

    @Test("prompt is suppressed one second inside the cooldown window")
    func justInsideCooldown() {
        let lastShown = Date(
            timeIntervalSince1970: now.timeIntervalSince1970 - PaywallPromptScheduler.cooldown + 1
        )
        let schedule = PaywallPromptSchedule(firstLaunchAt: ago(days: 60), lastShownAt: lastShown)
        #expect(PaywallPromptScheduler.shouldPrompt(tier: .free, schedule: schedule, now: now) == false)
    }

    @Test("trial period and cooldown match the documented durations")
    func documentedDurations() {
        #expect(PaywallPromptScheduler.trialPeriod == 60 * 60 * 24 * 14)
        #expect(PaywallPromptScheduler.cooldown == 60 * 60 * 24 * 7)
    }
}
