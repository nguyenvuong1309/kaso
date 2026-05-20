import Foundation
import Testing
@testable import BillSplitterDomain

struct BillSplitterDomainTests {
    @Test("equal split divides evenly")
    func equalSplit() {
        let p1 = BillParticipant(name: "Alice")
        let p2 = BillParticipant(name: "Bob")
        let split = BillSplit(
            title: "Lunch",
            participants: [p1, p2],
            items: [BillItem(label: "Pizza", amount: 200_000)],
            payerID: p1.id
        )
        let result = BillSplitCalculator.calculate(split: split)
        #expect(result.subtotal == 200_000)
        #expect(result.shares.count == 2)
        #expect(result.shares.allSatisfy { $0.owes == 100_000 })
        #expect(result.settlements.count == 1)
        #expect(result.settlements.first?.amount == 100_000)
    }

    @Test("assigned items only charge assignees")
    func assignedItems() {
        let p1 = BillParticipant(name: "Alice")
        let p2 = BillParticipant(name: "Bob")
        let split = BillSplit(
            participants: [p1, p2],
            items: [
                BillItem(label: "Wine", amount: 300_000, assignedTo: [p1.id]),
                BillItem(label: "Salad", amount: 100_000),
            ],
            payerID: p1.id
        )
        let result = BillSplitCalculator.calculate(split: split)
        let aliceShare = result.shares.first { $0.participantID == p1.id }?.owes
        let bobShare = result.shares.first { $0.participantID == p2.id }?.owes
        #expect(aliceShare == 350_000)
        #expect(bobShare == 50_000)
    }

    @Test("tip is split equally and added to total")
    func tipSplitEqually() {
        let p1 = BillParticipant(name: "Alice")
        let p2 = BillParticipant(name: "Bob")
        let split = BillSplit(
            participants: [p1, p2],
            items: [BillItem(label: "Bun bo", amount: 100_000)],
            payerID: p1.id,
            tipMode: .percent10
        )
        let result = BillSplitCalculator.calculate(split: split)
        #expect(result.tip == 10_000)
        #expect(result.total == 110_000)
        #expect(result.shares.allSatisfy { $0.owes == 55_000 })
    }
}
