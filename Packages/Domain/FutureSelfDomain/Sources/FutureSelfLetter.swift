import Foundation

public enum FutureSelfTone: String, Codable, Equatable, Sendable {
    case optimistic
    case steady
    case cautionary

    public var emoji: String {
        switch self {
        case .optimistic: "🌅"
        case .steady: "🌤️"
        case .cautionary: "🌧️"
        }
    }

    public var headlineKey: String { "futureSelf.tone.\(rawValue).headline" }
}

/// A deterministic, on-device "letter from your future self". No cloud AI is used —
/// the body is assembled from localized templates keyed by the financial trajectory.
public struct FutureSelfLetter: Equatable, Sendable {
    public let quarterLabel: String
    public let tone: FutureSelfTone
    public let projectedAge: Int
    public let projectedAnnualSavings: Decimal
    /// Localized template keys, rendered in order by the view.
    public let paragraphKeys: [String]
    public let savingsRate: Double
    public let generatedAt: Date
    public let isSufficient: Bool

    public init(
        quarterLabel: String,
        tone: FutureSelfTone,
        projectedAge: Int,
        projectedAnnualSavings: Decimal,
        paragraphKeys: [String],
        savingsRate: Double,
        generatedAt: Date,
        isSufficient: Bool
    ) {
        self.quarterLabel = quarterLabel
        self.tone = tone
        self.projectedAge = projectedAge
        self.projectedAnnualSavings = projectedAnnualSavings
        self.paragraphKeys = paragraphKeys
        self.savingsRate = savingsRate
        self.generatedAt = generatedAt
        self.isSufficient = isSufficient
    }

    public static let empty = FutureSelfLetter(
        quarterLabel: "",
        tone: .steady,
        projectedAge: 0,
        projectedAnnualSavings: 0,
        paragraphKeys: [],
        savingsRate: 0,
        generatedAt: Date(timeIntervalSinceReferenceDate: 0),
        isSufficient: false
    )
}
