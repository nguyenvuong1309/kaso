import Foundation

public struct BillShare: Identifiable, Equatable, Sendable {
    public var id: UUID { participantID }
    public let participantID: UUID
    public let name: String
    public let owes: Decimal
    public let isPayer: Bool

    public init(participantID: UUID, name: String, owes: Decimal, isPayer: Bool) {
        self.participantID = participantID
        self.name = name
        self.owes = owes
        self.isPayer = isPayer
    }
}

public struct BillSettlement: Identifiable, Equatable, Sendable {
    public var id: String { "\(fromID.uuidString)->\(toID.uuidString)" }
    public let fromID: UUID
    public let fromName: String
    public let toID: UUID
    public let toName: String
    public let amount: Decimal

    public init(
        fromID: UUID,
        fromName: String,
        toID: UUID,
        toName: String,
        amount: Decimal
    ) {
        self.fromID = fromID
        self.fromName = fromName
        self.toID = toID
        self.toName = toName
        self.amount = amount
    }
}

public struct BillSplitResult: Equatable, Sendable {
    public let subtotal: Decimal
    public let tip: Decimal
    public let total: Decimal
    public let shares: [BillShare]
    public let settlements: [BillSettlement]

    public init(
        subtotal: Decimal,
        tip: Decimal,
        total: Decimal,
        shares: [BillShare],
        settlements: [BillSettlement]
    ) {
        self.subtotal = subtotal
        self.tip = tip
        self.total = total
        self.shares = shares
        self.settlements = settlements
    }

    public static let empty = BillSplitResult(
        subtotal: 0,
        tip: 0,
        total: 0,
        shares: [],
        settlements: []
    )
}

public enum BillSplitCalculator {
    public static func calculate(split: BillSplit) -> BillSplitResult {
        guard split.participants.isEmpty == false else { return .empty }

        let subtotal = split.items.reduce(Decimal(0)) { $0 + $1.amount }
        let tipMultiplier: Decimal = {
            switch split.tipMode {
            case .none: 0
            case .percent10: Decimal(0.10)
            case .percent15: Decimal(0.15)
            case .percent20: Decimal(0.20)
            }
        }()
        let tip = subtotal * tipMultiplier
        let total = subtotal + tip

        // Each item's amount is allocated to its assigned participants (or all if none).
        var raw: [UUID: Decimal] = [:]
        for participant in split.participants {
            raw[participant.id] = 0
        }
        for item in split.items {
            let assignees = item.assignedTo.isEmpty ? split.participants.map(\.id) : item.assignedTo
            guard assignees.isEmpty == false else { continue }
            let share = item.amount / Decimal(assignees.count)
            for participantID in assignees where raw[participantID] != nil {
                raw[participantID, default: 0] += share
            }
        }

        // Tip is split equally among all participants.
        if tip > 0 {
            let perHead = tip / Decimal(split.participants.count)
            for participant in split.participants {
                raw[participant.id, default: 0] += perHead
            }
        }

        let shares = split.participants.map { participant in
            BillShare(
                participantID: participant.id,
                name: participant.name,
                owes: raw[participant.id] ?? 0,
                isPayer: participant.id == split.payerID
            )
        }

        // Settlements: if there's a payer, everyone else owes them their share.
        var settlements: [BillSettlement] = []
        if let payerID = split.payerID,
           let payer = split.participants.first(where: { $0.id == payerID }) {
            for share in shares where share.isPayer == false && share.owes > 0 {
                settlements.append(
                    BillSettlement(
                        fromID: share.participantID,
                        fromName: share.name,
                        toID: payer.id,
                        toName: payer.name,
                        amount: share.owes
                    )
                )
            }
        }

        return BillSplitResult(
            subtotal: subtotal,
            tip: tip,
            total: total,
            shares: shares,
            settlements: settlements
        )
    }
}
