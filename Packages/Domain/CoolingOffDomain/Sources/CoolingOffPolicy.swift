import Foundation

public struct CoolingOffPolicy: Codable, Equatable, Sendable {
    public struct Threshold: Codable, Equatable, Sendable {
        public var minAmount: Decimal
        public var period: CoolingPeriod

        public init(minAmount: Decimal, period: CoolingPeriod) {
            self.minAmount = minAmount
            self.period = period
        }
    }

    public var thresholds: [Threshold]
    public var defaultPeriod: CoolingPeriod

    public init(thresholds: [Threshold], defaultPeriod: CoolingPeriod = .oneDay) {
        self.thresholds = thresholds.sorted { $0.minAmount < $1.minAmount }
        self.defaultPeriod = defaultPeriod
    }

    public static let `default` = CoolingOffPolicy(
        thresholds: [
            Threshold(minAmount: 500_000, period: .oneDay),
            Threshold(minAmount: 2_000_000, period: .threeDays),
            Threshold(minAmount: 5_000_000, period: .oneWeek),
            Threshold(minAmount: 20_000_000, period: .twoWeeks),
        ],
        defaultPeriod: .oneDay
    )

    public func suggestedPeriod(for amount: Decimal) -> CoolingPeriod {
        var period = defaultPeriod
        for threshold in thresholds where threshold.minAmount <= amount {
            period = threshold.period
        }
        return period
    }
}
