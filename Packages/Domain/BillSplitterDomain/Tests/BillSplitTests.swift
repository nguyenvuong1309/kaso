import Foundation
import Testing
@testable import BillSplitterDomain

// MARK: - BillParticipant

@Test("BillParticipant uses supplied id and name")
func participantStoresIdentityAndName() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000A1"))
    let participant = BillParticipant(id: id, name: "Alice")
    #expect(participant.id == id)
    #expect(participant.name == "Alice")
}

@Test("BillParticipant equality compares id and name")
func participantEquality() {
    let id = UUID()
    let a = BillParticipant(id: id, name: "Alice")
    let b = BillParticipant(id: id, name: "Alice")
    let differentName = BillParticipant(id: id, name: "Bob")
    let differentID = BillParticipant(id: UUID(), name: "Alice")
    #expect(a == b)
    #expect(a != differentName)
    #expect(a != differentID)
}

@Test("BillParticipant is Hashable and usable as a Set element")
func participantHashable() {
    let id = UUID()
    let a = BillParticipant(id: id, name: "Alice")
    let aDuplicate = BillParticipant(id: id, name: "Alice")
    let other = BillParticipant(name: "Bob")
    let set: Set<BillParticipant> = [a, aDuplicate, other]
    #expect(set.count == 2)
    #expect(set.contains(a))
}

@Test("BillParticipant name is mutable")
func participantNameMutable() {
    var participant = BillParticipant(name: "Alice")
    participant.name = "Alicia"
    #expect(participant.name == "Alicia")
}

// MARK: - BillItem

@Test("BillItem defaults assignedTo to empty")
func itemDefaultsAssignedToEmpty() {
    let item = BillItem(label: "Pizza", amount: 200_000)
    #expect(item.label == "Pizza")
    #expect(item.amount == 200_000)
    #expect(item.assignedTo.isEmpty)
}

@Test("BillItem retains explicit assignees")
func itemRetainsAssignees() {
    let p1 = UUID()
    let p2 = UUID()
    let item = BillItem(label: "Wine", amount: 300_000, assignedTo: [p1, p2])
    #expect(item.assignedTo == [p1, p2])
}

@Test("BillItem equality compares all stored fields")
func itemEquality() {
    let id = UUID()
    let assignee = UUID()
    let base = BillItem(id: id, label: "Wine", amount: 300_000, assignedTo: [assignee])
    let same = BillItem(id: id, label: "Wine", amount: 300_000, assignedTo: [assignee])
    let differentAmount = BillItem(id: id, label: "Wine", amount: 100_000, assignedTo: [assignee])
    let differentAssignee = BillItem(id: id, label: "Wine", amount: 300_000, assignedTo: [])
    #expect(base == same)
    #expect(base != differentAmount)
    #expect(base != differentAssignee)
}

@Test("BillItem mutable fields can be reassigned")
func itemMutableFields() {
    var item = BillItem(label: "Soda", amount: 20_000)
    let assignee = UUID()
    item.label = "Cola"
    item.amount = 25_000
    item.assignedTo = [assignee]
    #expect(item.label == "Cola")
    #expect(item.amount == 25_000)
    #expect(item.assignedTo == [assignee])
}

// MARK: - BillTipMode

@Test("BillTipMode exposes all four cases")
func tipModeCaseIterable() {
    #expect(BillTipMode.allCases == [.none, .percent10, .percent15, .percent20])
}

@Test("BillTipMode raw values round-trip")
func tipModeRawValues() {
    #expect(BillTipMode.none.rawValue == "none")
    #expect(BillTipMode.percent10.rawValue == "percent10")
    #expect(BillTipMode.percent15.rawValue == "percent15")
    #expect(BillTipMode.percent20.rawValue == "percent20")
    #expect(BillTipMode(rawValue: "percent20") == .percent20)
    #expect(BillTipMode(rawValue: "unknown") == nil)
}

// MARK: - BillSplit

@Test("BillSplit default initializer produces empty defaults")
func splitDefaults() throws {
    let calendar = Calendar(identifier: .gregorian)
    let created = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let split = BillSplit(createdAt: created)
    #expect(split.title.isEmpty)
    #expect(split.participants.isEmpty)
    #expect(split.items.isEmpty)
    #expect(split.payerID == nil)
    #expect(split.tipMode == .none)
    #expect(split.createdAt == created)
}

@Test("BillSplit retains all supplied values")
func splitStoresValues() throws {
    let calendar = Calendar(identifier: .gregorian)
    let created = try makeDate(year: 2026, month: 1, day: 2, hour: 9, calendar: calendar)
    let p1 = BillParticipant(name: "Alice")
    let item = BillItem(label: "Pho", amount: 80_000)
    let split = BillSplit(
        title: "Dinner",
        participants: [p1],
        items: [item],
        payerID: p1.id,
        tipMode: .percent15,
        createdAt: created
    )
    #expect(split.title == "Dinner")
    #expect(split.participants == [p1])
    #expect(split.items == [item])
    #expect(split.payerID == p1.id)
    #expect(split.tipMode == .percent15)
    #expect(split.createdAt == created)
}

@Test("BillSplit equality reflects field differences")
func splitEquality() throws {
    let calendar = Calendar(identifier: .gregorian)
    let created = try makeDate(year: 2026, month: 3, day: 4, calendar: calendar)
    let id = UUID()
    let p1 = BillParticipant(name: "Alice")
    let base = BillSplit(id: id, title: "Lunch", participants: [p1], createdAt: created)
    let same = BillSplit(id: id, title: "Lunch", participants: [p1], createdAt: created)
    let differentTitle = BillSplit(id: id, title: "Brunch", participants: [p1], createdAt: created)
    #expect(base == same)
    #expect(base != differentTitle)
}

@Test("BillSplit mutable fields can be updated in place")
func splitMutableFields() throws {
    let calendar = Calendar(identifier: .gregorian)
    let created = try makeDate(year: 2026, month: 5, day: 5, calendar: calendar)
    var split = BillSplit(createdAt: created)
    let participant = BillParticipant(name: "Bob")
    split.title = "Trip"
    split.participants = [participant]
    split.items = [BillItem(label: "Gas", amount: 500_000)]
    split.payerID = participant.id
    split.tipMode = .percent20
    #expect(split.title == "Trip")
    #expect(split.participants.count == 1)
    #expect(split.items.count == 1)
    #expect(split.payerID == participant.id)
    #expect(split.tipMode == .percent20)
}

// MARK: - Helpers

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
