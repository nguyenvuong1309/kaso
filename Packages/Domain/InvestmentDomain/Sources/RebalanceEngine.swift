import Foundation

public enum RebalanceActionKind: String, Codable, Equatable, Sendable {
    case buy
    case sell
}

public struct RebalanceAction: Identifiable, Equatable, Sendable {
    public var id: AssetClass {
        assetClass
    }
    public var assetClass: AssetClass
    public var kind: RebalanceActionKind
    public var amount: Decimal
    public var currentFraction: Double
    public var targetFraction: Double

    public init(
        assetClass: AssetClass,
        kind: RebalanceActionKind,
        amount: Decimal,
        currentFraction: Double,
        targetFraction: Double
    ) {
        self.assetClass = assetClass
        self.kind = kind
        self.amount = amount
        self.currentFraction = currentFraction
        self.targetFraction = targetFraction
    }

    public var driftFraction: Double {
        currentFraction - targetFraction
    }
}

public struct RebalanceSuggestion: Equatable, Sendable {
    public var actions: [RebalanceAction]
    public var driftScore: Double

    public init(
        actions: [RebalanceAction],
        driftScore: Double
    ) {
        self.actions = actions
        self.driftScore = driftScore
    }

    public static let empty = RebalanceSuggestion(actions: [], driftScore: 0)

    public var isSignificant: Bool {
        driftScore >= 0.05
    }
}

public enum RebalanceEngine {
    public static let toleranceFraction = 0.005

    public static func suggest(
        breakdown: AllocationBreakdown,
        target: TargetAllocation
    ) -> RebalanceSuggestion {
        guard !target.fractions.isEmpty, breakdown.marketValue > 0 else {
            return .empty
        }

        let currentMap = Dictionary(uniqueKeysWithValues: breakdown.slices.map { ($0.assetClass, $0.fraction) })
        let totalDouble = NSDecimalNumber(decimal: breakdown.marketValue).doubleValue
        let assetClasses = Set(currentMap.keys).union(target.fractions.keys)

        var actions: [RebalanceAction] = []
        var drift = 0.0

        for assetClass in assetClasses {
            let currentFraction = currentMap[assetClass] ?? 0
            let targetFraction = target.fractions[assetClass] ?? 0
            let delta = targetFraction - currentFraction
            drift += abs(delta)

            if abs(delta) < toleranceFraction {
                continue
            }

            let amountDouble = abs(delta) * totalDouble
            let amount = Decimal(amountDouble)
            actions.append(
                RebalanceAction(
                    assetClass: assetClass,
                    kind: delta > 0 ? .buy : .sell,
                    amount: amount,
                    currentFraction: currentFraction,
                    targetFraction: targetFraction
                )
            )
        }

        let sorted = actions.sorted { abs($0.driftFraction) > abs($1.driftFraction) }
        return RebalanceSuggestion(
            actions: sorted,
            driftScore: drift / 2.0
        )
    }
}
