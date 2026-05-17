import Foundation

public struct PurchasePlanSummary: Equatable, Sendable {
    public var waiting: [PurchasePlan]
    public var ready: [PurchasePlan]
    public var decided: [PurchasePlan]
    public var totalWaitingAmount: Decimal
    public var totalAvoidedAmount: Decimal

    public init(
        waiting: [PurchasePlan],
        ready: [PurchasePlan],
        decided: [PurchasePlan],
        totalWaitingAmount: Decimal,
        totalAvoidedAmount: Decimal
    ) {
        self.waiting = waiting
        self.ready = ready
        self.decided = decided
        self.totalWaitingAmount = totalWaitingAmount
        self.totalAvoidedAmount = totalAvoidedAmount
    }

    public static let empty = PurchasePlanSummary(
        waiting: [],
        ready: [],
        decided: [],
        totalWaitingAmount: 0,
        totalAvoidedAmount: 0
    )
}

public enum PurchasePlanSummaryBuilder {
    public static func build(
        plans: [PurchasePlan],
        referenceDate: Date
    ) -> PurchasePlanSummary {
        var waiting: [PurchasePlan] = []
        var ready: [PurchasePlan] = []
        var decided: [PurchasePlan] = []
        var avoided = Decimal(0)
        var pendingTotal = Decimal(0)

        for plan in plans.sorted(by: { $0.availableAt < $1.availableAt }) {
            switch plan.status {
            case .waiting:
                if plan.isReady(asOf: referenceDate) {
                    ready.append(plan)
                } else {
                    waiting.append(plan)
                }
                pendingTotal += plan.amount
            case .approved, .cancelled, .expired:
                decided.append(plan)
                if plan.status == .cancelled || plan.status == .expired {
                    avoided += plan.amount
                }
            }
        }

        decided.sort { ($0.decisionAt ?? .distantPast) > ($1.decisionAt ?? .distantPast) }

        return PurchasePlanSummary(
            waiting: waiting,
            ready: ready,
            decided: decided,
            totalWaitingAmount: pendingTotal,
            totalAvoidedAmount: avoided
        )
    }
}
