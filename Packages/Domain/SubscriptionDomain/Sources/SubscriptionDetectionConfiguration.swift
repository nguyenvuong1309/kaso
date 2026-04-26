import Foundation

public struct SubscriptionDetectionConfiguration: Equatable, Sendable {
    public var minimumOccurrences: Int
    public var amountVarianceTolerance: Decimal
    public var minimumIntervalMatchRatio: Double

    public init(
        minimumOccurrences: Int = 2,
        amountVarianceTolerance: Decimal = Decimal(15) / Decimal(100),
        minimumIntervalMatchRatio: Double = 0.75
    ) {
        self.minimumOccurrences = minimumOccurrences
        self.amountVarianceTolerance = amountVarianceTolerance
        self.minimumIntervalMatchRatio = minimumIntervalMatchRatio
    }
}
