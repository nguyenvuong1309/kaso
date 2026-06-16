import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiGroupTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        )
        return try #require(components.date)
    }

    @Test("initializer stores all provided values with defaults")
    func initializerStoresValues() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1"))
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let created = try makeDate(year: 2026, month: 1, day: 2)
        let group = HuiGroup(
            id: id,
            name: "Group",
            organizerName: "Organizer",
            contributionAmount: 2_000_000,
            periodKind: .monthly,
            memberCount: 6,
            startDate: start,
            createdAt: created
        )

        #expect(group.id == id)
        #expect(group.name == "Group")
        #expect(group.organizerName == "Organizer")
        #expect(group.contributionAmount == 2_000_000)
        #expect(group.periodKind == .monthly)
        #expect(group.memberCount == 6)
        #expect(group.startDate == start)
        #expect(group.note == nil)
        #expect(group.cycles.isEmpty)
        #expect(group.createdAt == created)
    }

    @Test("codable round-trip preserves group including cycles")
    func codableRoundTrip() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A2"))
        let cycleID = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A3"))
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let created = try makeDate(year: 2026, month: 1, day: 2)
        let due = try makeDate(year: 2026, month: 2, day: 1)
        let group = HuiGroup(
            id: id,
            name: "Group",
            organizerName: "Org",
            contributionAmount: 1_500_000,
            periodKind: .biweekly,
            memberCount: 4,
            startDate: start,
            note: "note",
            cycles: [HuiCycle(id: cycleID, index: 1, dueDate: due, isPaid: true)],
            createdAt: created
        )

        let encoded = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(HuiGroup.self, from: encoded)
        #expect(decoded == group)
    }

    @Test("two groups with identical fields are equal")
    func equality() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A4"))
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let created = try makeDate(year: 2026, month: 1, day: 2)
        let lhs = HuiGroup(
            id: id,
            name: "G",
            organizerName: "O",
            contributionAmount: 1_000_000,
            periodKind: .weekly,
            memberCount: 2,
            startDate: start,
            createdAt: created
        )
        let rhs = HuiGroup(
            id: id,
            name: "G",
            organizerName: "O",
            contributionAmount: 1_000_000,
            periodKind: .weekly,
            memberCount: 2,
            startDate: start,
            createdAt: created
        )
        #expect(lhs == rhs)
    }

    @Test("groups differing by contribution amount are not equal")
    func inequalityByAmount() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A5"))
        let start = try makeDate(year: 2026, month: 1, day: 1)
        let created = try makeDate(year: 2026, month: 1, day: 2)
        let lhs = HuiGroup(
            id: id,
            name: "G",
            organizerName: "O",
            contributionAmount: 1_000_000,
            periodKind: .weekly,
            memberCount: 2,
            startDate: start,
            createdAt: created
        )
        let rhs = HuiGroup(
            id: id,
            name: "G",
            organizerName: "O",
            contributionAmount: 2_000_000,
            periodKind: .weekly,
            memberCount: 2,
            startDate: start,
            createdAt: created
        )
        #expect(lhs != rhs)
    }
}
