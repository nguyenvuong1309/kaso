import Foundation

public struct HuiGroupSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var totalContributed: Decimal
    public var totalReceived: Decimal
    public var paidCycleCount: Int
    public var totalCycleCount: Int
    public var nextDueDate: Date?
    public var nextDueIndex: Int?

    public var netPosition: Decimal { totalReceived - totalContributed }

    public var isComplete: Bool {
        totalCycleCount > 0 && paidCycleCount == totalCycleCount
    }

    public init(
        id: UUID,
        name: String,
        totalContributed: Decimal,
        totalReceived: Decimal,
        paidCycleCount: Int,
        totalCycleCount: Int,
        nextDueDate: Date?,
        nextDueIndex: Int?
    ) {
        self.id = id
        self.name = name
        self.totalContributed = totalContributed
        self.totalReceived = totalReceived
        self.paidCycleCount = paidCycleCount
        self.totalCycleCount = totalCycleCount
        self.nextDueDate = nextDueDate
        self.nextDueIndex = nextDueIndex
    }
}

public struct HuiOverallSummary: Equatable, Sendable {
    public var totalContributed: Decimal
    public var totalReceived: Decimal
    public var activeGroupCount: Int

    public var netPosition: Decimal { totalReceived - totalContributed }

    public init(
        totalContributed: Decimal = 0,
        totalReceived: Decimal = 0,
        activeGroupCount: Int = 0
    ) {
        self.totalContributed = totalContributed
        self.totalReceived = totalReceived
        self.activeGroupCount = activeGroupCount
    }
}

public enum HuiSummaryBuilder {
    public static func group(from group: HuiGroup) -> HuiGroupSummary {
        let paidCycles = group.cycles.filter(\.isPaid)
        let totalContributed = Decimal(paidCycles.count) * group.contributionAmount
        let totalReceived = group.cycles
            .filter(\.isReceived)
            .reduce(Decimal(0)) { $0 + ($1.receivedAmount ?? 0) }
        let nextDue = group.cycles
            .filter { $0.isPaid == false }
            .min { $0.dueDate < $1.dueDate }

        return HuiGroupSummary(
            id: group.id,
            name: group.name,
            totalContributed: totalContributed,
            totalReceived: totalReceived,
            paidCycleCount: paidCycles.count,
            totalCycleCount: group.cycles.count,
            nextDueDate: nextDue?.dueDate,
            nextDueIndex: nextDue?.index
        )
    }

    public static func overall(from groups: [HuiGroup]) -> HuiOverallSummary {
        let summaries = groups.map(group(from:))
        return HuiOverallSummary(
            totalContributed: summaries.reduce(Decimal(0)) { $0 + $1.totalContributed },
            totalReceived: summaries.reduce(Decimal(0)) { $0 + $1.totalReceived },
            activeGroupCount: summaries.filter { $0.isComplete == false }.count
        )
    }
}
