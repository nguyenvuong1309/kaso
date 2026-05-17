import Foundation

public struct RegretCategorySummary: Identifiable, Equatable, Sendable {
    public var category: String
    public var ratingCount: Int
    public var regretRatio: Double
    public var totalRegretedAmount: Decimal

    public init(category: String, ratingCount: Int, regretRatio: Double, totalRegretedAmount: Decimal) {
        self.category = category
        self.ratingCount = ratingCount
        self.regretRatio = regretRatio
        self.totalRegretedAmount = totalRegretedAmount
    }

    public var id: String {
        category
    }
}

public struct RegretSummary: Equatable, Sendable {
    public var ratings: [RegretRating]
    public var totalCount: Int
    public var regretCount: Int
    public var regretRatio: Double
    public var totalRegretedAmount: Decimal
    public var categorySummaries: [RegretCategorySummary]
    public var topRegretedPurchases: [RegretRating]

    public init(
        ratings: [RegretRating],
        totalCount: Int,
        regretCount: Int,
        regretRatio: Double,
        totalRegretedAmount: Decimal,
        categorySummaries: [RegretCategorySummary],
        topRegretedPurchases: [RegretRating]
    ) {
        self.ratings = ratings
        self.totalCount = totalCount
        self.regretCount = regretCount
        self.regretRatio = regretRatio
        self.totalRegretedAmount = totalRegretedAmount
        self.categorySummaries = categorySummaries
        self.topRegretedPurchases = topRegretedPurchases
    }

    public static let empty = RegretSummary(
        ratings: [],
        totalCount: 0,
        regretCount: 0,
        regretRatio: 0,
        totalRegretedAmount: 0,
        categorySummaries: [],
        topRegretedPurchases: []
    )
}

public enum RegretSummaryBuilder {
    public static func build(ratings: [RegretRating]) -> RegretSummary {
        guard ratings.isEmpty == false else {
            return .empty
        }

        let regretedRatings = ratings.filter { $0.score.isRegret }
        let totalRegretedAmount = regretedRatings.reduce(Decimal(0)) { $0 + $1.amount }

        let grouped = Dictionary(grouping: ratings, by: \.category)
        let summaries = grouped
            .map { category, items -> RegretCategorySummary in
                let regrets = items.filter { $0.score.isRegret }
                let ratio = items.isEmpty ? 0 : Double(regrets.count) / Double(items.count)
                let amount = regrets.reduce(Decimal(0)) { $0 + $1.amount }
                return RegretCategorySummary(
                    category: category,
                    ratingCount: items.count,
                    regretRatio: ratio,
                    totalRegretedAmount: amount
                )
            }
            .sorted { $0.regretRatio > $1.regretRatio }

        let top = regretedRatings
            .sorted { lhs, rhs in
                if lhs.score.rawValue == rhs.score.rawValue {
                    return lhs.amount > rhs.amount
                }
                return lhs.score.rawValue > rhs.score.rawValue
            }
            .prefix(5)
            .map { $0 }

        return RegretSummary(
            ratings: ratings.sorted { $0.ratedAt > $1.ratedAt },
            totalCount: ratings.count,
            regretCount: regretedRatings.count,
            regretRatio: Double(regretedRatings.count) / Double(ratings.count),
            totalRegretedAmount: totalRegretedAmount,
            categorySummaries: summaries,
            topRegretedPurchases: top
        )
    }
}
