import Foundation

public struct NetWorthSnapshot: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var date: Date
    public var totalAssets: Decimal
    public var totalLiabilities: Decimal

    public init(
        id: UUID = UUID(),
        date: Date,
        totalAssets: Decimal,
        totalLiabilities: Decimal
    ) {
        self.id = id
        self.date = date
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
    }

    public var netWorth: Decimal {
        totalAssets - totalLiabilities
    }

    public func growth(comparedTo previous: NetWorthSnapshot?) -> NetWorthGrowth {
        guard let previous else {
            return NetWorthGrowth(absoluteDelta: 0, percentDelta: 0, hasBaseline: false)
        }

        let absoluteDelta = netWorth - previous.netWorth
        let baseline = abs(previous.netWorth)
        let percent: Double
        if baseline == 0 {
            percent = absoluteDelta == 0 ? 0 : 1
        } else {
            let baselineDouble = NSDecimalNumber(decimal: baseline).doubleValue
            let deltaDouble = NSDecimalNumber(decimal: absoluteDelta).doubleValue
            percent = deltaDouble / baselineDouble
        }

        return NetWorthGrowth(
            absoluteDelta: absoluteDelta,
            percentDelta: percent,
            hasBaseline: true
        )
    }
}

public struct NetWorthGrowth: Equatable, Sendable {
    public var absoluteDelta: Decimal
    public var percentDelta: Double
    public var hasBaseline: Bool

    public init(
        absoluteDelta: Decimal,
        percentDelta: Double,
        hasBaseline: Bool
    ) {
        self.absoluteDelta = absoluteDelta
        self.percentDelta = percentDelta
        self.hasBaseline = hasBaseline
    }

    public var isPositive: Bool {
        absoluteDelta > 0
    }

    public var isNegative: Bool {
        absoluteDelta < 0
    }
}
