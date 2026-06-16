import Foundation
import Testing
@testable import BillSplitterDomain

// MARK: - BillShare

@Test("BillShare id mirrors participantID")
func shareIDMirrorsParticipant() {
    let participantID = UUID()
    let share = BillShare(participantID: participantID, name: "Alice", owes: 100_000, isPayer: false)
    #expect(share.id == participantID)
    #expect(share.name == "Alice")
    #expect(share.owes == 100_000)
    #expect(share.isPayer == false)
}

@Test("BillShare equality compares stored fields")
func shareEquality() {
    let participantID = UUID()
    let base = BillShare(participantID: participantID, name: "Alice", owes: 100_000, isPayer: true)
    let same = BillShare(participantID: participantID, name: "Alice", owes: 100_000, isPayer: true)
    let differentOwes = BillShare(participantID: participantID, name: "Alice", owes: 50_000, isPayer: true)
    #expect(base == same)
    #expect(base != differentOwes)
}

// MARK: - BillSettlement

@Test("BillSettlement id encodes direction")
func settlementIDEncodesDirection() {
    let from = UUID()
    let to = UUID()
    let settlement = BillSettlement(
        fromID: from,
        fromName: "Bob",
        toID: to,
        toName: "Alice",
        amount: 75_000
    )
    #expect(settlement.id == "\(from.uuidString)->\(to.uuidString)")
    #expect(settlement.fromName == "Bob")
    #expect(settlement.toName == "Alice")
    #expect(settlement.amount == 75_000)
}

@Test("BillSettlement equality compares stored fields")
func settlementEquality() {
    let from = UUID()
    let to = UUID()
    let base = BillSettlement(fromID: from, fromName: "Bob", toID: to, toName: "Alice", amount: 75_000)
    let same = BillSettlement(fromID: from, fromName: "Bob", toID: to, toName: "Alice", amount: 75_000)
    let differentAmount = BillSettlement(fromID: from, fromName: "Bob", toID: to, toName: "Alice", amount: 10)
    #expect(base == same)
    #expect(base != differentAmount)
}

// MARK: - BillSplitResult

@Test("BillSplitResult.empty is all zeros and empty collections")
func resultEmpty() {
    let empty = BillSplitResult.empty
    #expect(empty.subtotal == 0)
    #expect(empty.tip == 0)
    #expect(empty.total == 0)
    #expect(empty.shares.isEmpty)
    #expect(empty.settlements.isEmpty)
}

@Test("BillSplitResult equality compares all fields")
func resultEquality() {
    let share = BillShare(participantID: UUID(), name: "A", owes: 1, isPayer: false)
    let a = BillSplitResult(subtotal: 1, tip: 0, total: 1, shares: [share], settlements: [])
    let b = BillSplitResult(subtotal: 1, tip: 0, total: 1, shares: [share], settlements: [])
    let c = BillSplitResult(subtotal: 2, tip: 0, total: 2, shares: [share], settlements: [])
    #expect(a == b)
    #expect(a != c)
}

// MARK: - BillSplitCalculator edge cases

@Test("calculate returns empty when there are no participants")
func calculateNoParticipants() {
    let split = BillSplit(items: [BillItem(label: "Pizza", amount: 200_000)])
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result == .empty)
}

@Test("calculate handles participants with no items")
func calculateNoItems() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(participants: [p1, p2], payerID: p1.id)
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.subtotal == 0)
    #expect(result.tip == 0)
    #expect(result.total == 0)
    #expect(result.shares.count == 2)
    #expect(result.shares.allSatisfy { $0.owes == 0 })
    #expect(result.settlements.isEmpty)
}

@Test("calculate produces no settlements when there is no payer")
func calculateNoPayer() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Pizza", amount: 200_000)]
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.shares.allSatisfy { $0.owes == 100_000 })
    #expect(result.shares.allSatisfy { $0.isPayer == false })
    #expect(result.settlements.isEmpty)
}

@Test("payer is flagged and never appears as a debtor")
func payerNotInSettlements() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Pizza", amount: 200_000)],
        payerID: p1.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    let payerShare = result.shares.first { $0.participantID == p1.id }
    #expect(payerShare?.isPayer == true)
    #expect(result.settlements.count == 1)
    #expect(result.settlements.first?.fromID == p2.id)
    #expect(result.settlements.first?.toID == p1.id)
    #expect(result.settlements.first?.toName == "Alice")
}

@Test("multiple debtors each owe the payer")
func multipleDebtors() {
    let payer = BillParticipant(name: "Alice")
    let bob = BillParticipant(name: "Bob")
    let cara = BillParticipant(name: "Cara")
    let split = BillSplit(
        participants: [payer, bob, cara],
        items: [BillItem(label: "Dinner", amount: 300_000)],
        payerID: payer.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.shares.allSatisfy { $0.owes == 100_000 })
    #expect(result.settlements.count == 2)
    #expect(result.settlements.allSatisfy { $0.toID == payer.id })
    #expect(result.settlements.allSatisfy { $0.amount == 100_000 })
    let debtorIDs = Set(result.settlements.map(\.fromID))
    #expect(debtorIDs == [bob.id, cara.id])
}

@Test("participant who owes nothing is excluded from settlements")
func zeroOwingExcludedFromSettlements() {
    let payer = BillParticipant(name: "Alice")
    let bob = BillParticipant(name: "Bob")
    let cara = BillParticipant(name: "Cara")
    // Only Bob is assigned the single item; Cara owes nothing.
    let split = BillSplit(
        participants: [payer, bob, cara],
        items: [BillItem(label: "Solo dish", amount: 90_000, assignedTo: [bob.id])],
        payerID: payer.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    let caraShare = result.shares.first { $0.participantID == cara.id }
    #expect(caraShare?.owes == 0)
    #expect(result.settlements.count == 1)
    #expect(result.settlements.first?.fromID == bob.id)
    #expect(result.settlements.first?.amount == 90_000)
}

@Test("tip percent15 splits equally and adds to total")
func tipPercent15() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Meal", amount: 100_000)],
        payerID: p1.id,
        tipMode: .percent15
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.tip == 15_000)
    #expect(result.total == 115_000)
    #expect(result.shares.allSatisfy { $0.owes == 57_500 })
}

@Test("tip percent20 splits equally and adds to total")
func tipPercent20() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Meal", amount: 100_000)],
        payerID: p1.id,
        tipMode: .percent20
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.tip == 20_000)
    #expect(result.total == 120_000)
    #expect(result.shares.allSatisfy { $0.owes == 60_000 })
}

@Test("tip none leaves total equal to subtotal")
func tipNone() {
    let p1 = BillParticipant(name: "Alice")
    let split = BillSplit(
        participants: [p1],
        items: [BillItem(label: "Meal", amount: 100_000)],
        payerID: p1.id,
        tipMode: .none
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.tip == 0)
    #expect(result.total == 100_000)
}

@Test("tip is distributed across all participants even when items are assigned")
func tipAcrossAllDespiteAssignment() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    // Item assigned only to Alice; tip still split between both.
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Wine", amount: 200_000, assignedTo: [p1.id])],
        payerID: p1.id,
        tipMode: .percent10
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.tip == 20_000)
    let aliceOwes = result.shares.first { $0.participantID == p1.id }?.owes
    let bobOwes = result.shares.first { $0.participantID == p2.id }?.owes
    #expect(aliceOwes == 210_000) // 200k item + 10k tip
    #expect(bobOwes == 10_000)    // tip only
}

@Test("item assigned to an unknown id is dropped from allocation")
func unknownAssigneeIgnored() {
    let p1 = BillParticipant(name: "Alice")
    let unknown = UUID()
    let split = BillSplit(
        participants: [p1],
        items: [BillItem(label: "Ghost", amount: 100_000, assignedTo: [unknown])],
        payerID: p1.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    // Subtotal still counts the item, but no known participant is charged.
    #expect(result.subtotal == 100_000)
    #expect(result.shares.first?.owes == 0)
    #expect(result.settlements.isEmpty)
}

@Test("zero-amount item leaves shares unchanged")
func zeroAmountItem() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Free water", amount: 0)],
        payerID: p1.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.subtotal == 0)
    #expect(result.shares.allSatisfy { $0.owes == 0 })
    #expect(result.settlements.isEmpty)
}

@Test("payerID referencing a missing participant produces no settlements")
func payerNotInParticipants() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [BillItem(label: "Pizza", amount: 200_000)],
        payerID: UUID() // not a participant
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.shares.allSatisfy { $0.isPayer == false })
    #expect(result.settlements.isEmpty)
}

@Test("multiple items aggregate per participant")
func multipleItemsAggregate() {
    let p1 = BillParticipant(name: "Alice")
    let p2 = BillParticipant(name: "Bob")
    let split = BillSplit(
        participants: [p1, p2],
        items: [
            BillItem(label: "Shared", amount: 100_000),
            BillItem(label: "Alice only", amount: 60_000, assignedTo: [p1.id]),
            BillItem(label: "Bob only", amount: 40_000, assignedTo: [p2.id]),
        ],
        payerID: p1.id
    )
    let result = BillSplitCalculator.calculate(split: split)
    #expect(result.subtotal == 200_000)
    let aliceOwes = result.shares.first { $0.participantID == p1.id }?.owes
    let bobOwes = result.shares.first { $0.participantID == p2.id }?.owes
    #expect(aliceOwes == 110_000) // 50k shared + 60k own
    #expect(bobOwes == 90_000)    // 50k shared + 40k own
    #expect(result.settlements.count == 1)
    #expect(result.settlements.first?.amount == 90_000)
}
