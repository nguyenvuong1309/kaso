import Foundation

public enum RoundUpStep: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case oneThousand = 1_000
    case fiveThousand = 5_000
    case tenThousand = 10_000
    case fiftyThousand = 50_000

    public var id: Int {
        rawValue
    }

    public var nameKey: String {
        "roundUp.step.\(rawValue)"
    }

    public var amount: Decimal {
        Decimal(rawValue)
    }
}
