import Foundation
import Testing
@testable import GiftTrackerDomain

struct GiftTrackerDomainTests {
    @Test("GiftPersonSummaryBuilder groups records by personName")
    func summaryGroupsByPerson() {
        let now = Date()
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .month, value: -3, to: now) ?? now

        let records = [
            GiftRecord(
                personName: "Hùng",
                eventKind: .wedding,
                direction: .given,
                amount: 1_000_000,
                eventDate: now
            ),
            GiftRecord(
                personName: "Hùng",
                eventKind: .tet,
                direction: .received,
                amount: 500_000,
                eventDate: lastYear
            ),
            GiftRecord(
                personName: "Mai",
                eventKind: .babyShower,
                direction: .given,
                amount: 300_000,
                eventDate: now
            ),
        ]

        let summaries = GiftPersonSummaryBuilder.build(from: records)

        #expect(summaries.count == 2)
        let hung = summaries.first { $0.personName == "Hùng" }
        #expect(hung?.totalGiven == 1_000_000)
        #expect(hung?.totalReceived == 500_000)
        #expect(hung?.records.count == 2)
    }

    @Test("GiftPersonSummary suggestedAmount averages given history")
    func suggestedAmountUsesGivenHistory() {
        let now = Date()
        let records = [
            GiftRecord(personName: "A", eventKind: .wedding, direction: .given, amount: 1_000_000, eventDate: now),
            GiftRecord(personName: "A", eventKind: .wedding, direction: .given, amount: 500_000, eventDate: now),
            GiftRecord(personName: "A", eventKind: .tet, direction: .received, amount: 200_000, eventDate: now),
        ]

        let summaries = GiftPersonSummaryBuilder.build(from: records)
        let a = summaries.first { $0.personName == "A" }

        #expect(a?.suggestedAmount == 750_000)
    }

    @Test("GiftYearlySummaryBuilder filters records by current year")
    func yearlySummaryFiltersCurrentYear() {
        let calendar = Calendar.current
        let now = Date()
        let lastYear = calendar.date(byAdding: .year, value: -1, to: now) ?? now

        let records = [
            GiftRecord(personName: "A", eventKind: .tet, direction: .given, amount: 500_000, eventDate: now),
            GiftRecord(personName: "B", eventKind: .tet, direction: .received, amount: 200_000, eventDate: now),
            GiftRecord(personName: "C", eventKind: .tet, direction: .given, amount: 1_000_000, eventDate: lastYear),
        ]

        let summary = GiftYearlySummaryBuilder.build(from: records, calendar: calendar)

        #expect(summary.year == calendar.component(.year, from: now))
        #expect(summary.totalGiven == 500_000)
        #expect(summary.totalReceived == 200_000)
        #expect(summary.recordCount == 2)
    }

    @Test("netBalance correctly computes received minus given")
    func netBalanceCalculation() {
        let summary = GiftPersonSummary(
            personName: "Test",
            totalGiven: 1_000_000,
            totalReceived: 800_000,
            lastEventDate: Date(),
            lastEventKind: .wedding,
            records: []
        )

        #expect(summary.netBalance == -200_000)
    }
}
