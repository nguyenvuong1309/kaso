import Foundation
import Testing
@testable import HuiTrackerDomain

struct HuiCycleTests {
    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        calendar: Calendar = Calendar(identifier: .gregorian)
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

    @Test("default initializer leaves optional flags unset")
    func defaultsAreUnset() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let due = try makeDate(year: 2026, month: 1, day: 15)
        let cycle = HuiCycle(id: try #require(id), index: 1, dueDate: due)

        #expect(cycle.index == 1)
        #expect(cycle.dueDate == due)
        #expect(cycle.isPaid == false)
        #expect(cycle.isReceived == false)
        #expect(cycle.receivedAmount == nil)
        #expect(cycle.note == nil)
    }

    @Test("full initializer stores all provided values")
    func fullInitializer() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let due = try makeDate(year: 2026, month: 2, day: 20)
        let cycle = HuiCycle(
            id: id,
            index: 3,
            dueDate: due,
            isPaid: true,
            isReceived: true,
            receivedAmount: 5_000_000,
            note: "received"
        )

        #expect(cycle.id == id)
        #expect(cycle.index == 3)
        #expect(cycle.isPaid)
        #expect(cycle.isReceived)
        #expect(cycle.receivedAmount == 5_000_000)
        #expect(cycle.note == "received")
    }

    @Test("two cycles with identical fields are equal")
    func equality() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))
        let due = try makeDate(year: 2026, month: 3, day: 1)
        let lhs = HuiCycle(id: id, index: 2, dueDate: due, isPaid: true)
        let rhs = HuiCycle(id: id, index: 2, dueDate: due, isPaid: true)
        #expect(lhs == rhs)
    }

    @Test("cycles differing only by isPaid are not equal")
    func inequalityByFlag() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000004"))
        let due = try makeDate(year: 2026, month: 3, day: 1)
        let lhs = HuiCycle(id: id, index: 2, dueDate: due, isPaid: true)
        let rhs = HuiCycle(id: id, index: 2, dueDate: due, isPaid: false)
        #expect(lhs != rhs)
    }

    @Test("codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000005"))
        let due = try makeDate(year: 2026, month: 4, day: 10)
        let original = HuiCycle(
            id: id,
            index: 4,
            dueDate: due,
            isPaid: true,
            isReceived: true,
            receivedAmount: 7_500_000,
            note: "note"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HuiCycle.self, from: encoded)
        #expect(decoded == original)
    }

    @Test("codable round-trip preserves nil optionals")
    func codableRoundTripWithNils() throws {
        let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000006"))
        let due = try makeDate(year: 2026, month: 5, day: 5)
        let original = HuiCycle(id: id, index: 1, dueDate: due)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HuiCycle.self, from: encoded)
        #expect(decoded == original)
        #expect(decoded.receivedAmount == nil)
        #expect(decoded.note == nil)
    }
}
