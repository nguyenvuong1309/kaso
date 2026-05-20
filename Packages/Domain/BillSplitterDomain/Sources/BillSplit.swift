import Foundation

public struct BillParticipant: Identifiable, Equatable, Sendable, Hashable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct BillItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var label: String
    public var amount: Decimal
    public var assignedTo: [UUID]   // participant IDs; empty == split among all

    public init(
        id: UUID = UUID(),
        label: String,
        amount: Decimal,
        assignedTo: [UUID] = []
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.assignedTo = assignedTo
    }
}

public enum BillTipMode: String, Sendable, Equatable, CaseIterable {
    case none
    case percent10
    case percent15
    case percent20
}

public struct BillSplit: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var participants: [BillParticipant]
    public var items: [BillItem]
    public var payerID: UUID?
    public var tipMode: BillTipMode
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "",
        participants: [BillParticipant] = [],
        items: [BillItem] = [],
        payerID: UUID? = nil,
        tipMode: BillTipMode = .none,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.participants = participants
        self.items = items
        self.payerID = payerID
        self.tipMode = tipMode
        self.createdAt = createdAt
    }
}
