import Foundation

public struct RegretReminderCandidate: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var transactionID: UUID
    public var title: String
    public var category: String
    public var amount: Decimal
    public var occurredAt: Date

    public init(
        id: UUID = UUID(),
        transactionID: UUID,
        title: String,
        category: String,
        amount: Decimal,
        occurredAt: Date
    ) {
        self.id = id
        self.transactionID = transactionID
        self.title = title
        self.category = category
        self.amount = amount
        self.occurredAt = occurredAt
    }
}

public struct RegretReminderInput: Equatable, Sendable {
    public var transactionID: UUID
    public var title: String
    public var category: String
    public var amount: Decimal
    public var occurredAt: Date

    public init(
        transactionID: UUID,
        title: String,
        category: String,
        amount: Decimal,
        occurredAt: Date
    ) {
        self.transactionID = transactionID
        self.title = title
        self.category = category
        self.amount = amount
        self.occurredAt = occurredAt
    }
}

public enum RegretReminderBuilder {
    public static let defaultMinDaysSincePurchase = 7
    public static let defaultMinAmount: Decimal = 500_000

    public static func reminders(
        from inputs: [RegretReminderInput],
        ratings: [RegretRating],
        referenceDate: Date,
        minDaysSincePurchase: Int = defaultMinDaysSincePurchase,
        minAmount: Decimal = defaultMinAmount
    ) -> [RegretReminderCandidate] {
        let ratedTransactions = Set(ratings.compactMap { rating -> UUID? in
            // Use ratedAt to match by ratingId not transactionId; consumers store transactionID in note path.
            // Since RegretRating doesn't carry transactionID directly, treat purchases as covered when
            // a rating exists with same title + occurredAt approximately. We keep it simple and
            // dedupe by amount + day later.
            _ = rating
            return nil
        })
        _ = ratedTransactions
        let ratedTitles: Set<String> = Set(ratings.map { "\($0.purchaseTitle.lowercased())-\(Self.dayKey($0.purchasedAt))-\($0.amount)" })

        let cutoff = referenceDate.addingTimeInterval(-Double(minDaysSincePurchase) * 86_400)

        return inputs
            .filter { input in
                input.amount >= minAmount &&
                    input.occurredAt <= cutoff &&
                    ratedTitles.contains(
                        "\(input.title.lowercased())-\(Self.dayKey(input.occurredAt))-\(input.amount)"
                    ) == false
            }
            .sorted { $0.amount > $1.amount }
            .map {
                RegretReminderCandidate(
                    transactionID: $0.transactionID,
                    title: $0.title,
                    category: $0.category,
                    amount: $0.amount,
                    occurredAt: $0.occurredAt
                )
            }
    }

    private static func dayKey(_ date: Date) -> String {
        let components = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
