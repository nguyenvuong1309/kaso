import Foundation

public struct RoundUpRule: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var step: RoundUpStep
    public var maxContributionPerTransaction: Decimal?
    public var linkedSavingGoalID: UUID?

    public init(
        isEnabled: Bool = false,
        step: RoundUpStep = .tenThousand,
        maxContributionPerTransaction: Decimal? = nil,
        linkedSavingGoalID: UUID? = nil
    ) {
        self.isEnabled = isEnabled
        self.step = step
        self.maxContributionPerTransaction = maxContributionPerTransaction
        self.linkedSavingGoalID = linkedSavingGoalID
    }
}
