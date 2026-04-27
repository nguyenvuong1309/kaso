import Foundation
import TransactionDomain

public enum AnonymousBenchmarkCity: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case hoChiMinh
    case haNoi
    case daNang
    case otherUrban

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "benchmark.city.\(rawValue)"
    }
}

public enum AnonymousBenchmarkAgeGroup: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case underTwentyFive
    case twentyFiveToThirtyFour
    case thirtyFiveToFortyFour
    case fortyFivePlus

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "benchmark.age.\(rawValue)"
    }
}

public enum AnonymousBenchmarkIncomeBand: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case underTenMillion
    case tenToTwentyMillion
    case twentyToFortyMillion
    case overFortyMillion

    public var id: String {
        rawValue
    }

    public var titleKey: String {
        "benchmark.income.\(rawValue)"
    }

    public static func inferred(from monthlyIncome: Decimal?) -> AnonymousBenchmarkIncomeBand {
        guard let monthlyIncome else {
            return .tenToTwentyMillion
        }

        if monthlyIncome < 10_000_000 {
            return .underTenMillion
        }

        if monthlyIncome < 20_000_000 {
            return .tenToTwentyMillion
        }

        if monthlyIncome < 40_000_000 {
            return .twentyToFortyMillion
        }

        return .overFortyMillion
    }
}

public struct AnonymousBenchmarkProfile: Codable, Equatable, Sendable {
    public var city: AnonymousBenchmarkCity
    public var ageGroup: AnonymousBenchmarkAgeGroup
    public var incomeBand: AnonymousBenchmarkIncomeBand

    public init(
        city: AnonymousBenchmarkCity = .hoChiMinh,
        ageGroup: AnonymousBenchmarkAgeGroup = .twentyFiveToThirtyFour,
        incomeBand: AnonymousBenchmarkIncomeBand = .tenToTwentyMillion
    ) {
        self.city = city
        self.ageGroup = ageGroup
        self.incomeBand = incomeBand
    }
}

public enum AnonymousBenchmarkStatus: String, Codable, Equatable, Sendable {
    case belowMedian
    case nearMedian
    case aboveMedian

    public var titleKey: String {
        "benchmark.status.\(rawValue)"
    }
}

public struct AnonymousBenchmarkCategoryComparison: Identifiable, Equatable, Sendable {
    public var id: String {
        category.id
    }

    public var category: TransactionCategory
    public var userAmount: Decimal
    public var benchmarkAmount: Decimal
    public var differenceAmount: Decimal
    public var differenceRatio: Decimal
    public var status: AnonymousBenchmarkStatus
    public var peerPercentile: Int

    public init(
        category: TransactionCategory,
        userAmount: Decimal,
        benchmarkAmount: Decimal,
        differenceAmount: Decimal,
        differenceRatio: Decimal,
        status: AnonymousBenchmarkStatus,
        peerPercentile: Int
    ) {
        self.category = category
        self.userAmount = userAmount
        self.benchmarkAmount = benchmarkAmount
        self.differenceAmount = differenceAmount
        self.differenceRatio = differenceRatio
        self.status = status
        self.peerPercentile = peerPercentile
    }
}

public struct AnonymousBenchmarkReport: Equatable, Sendable {
    public var profile: AnonymousBenchmarkProfile
    public var totalUserExpense: Decimal
    public var totalBenchmarkExpense: Decimal
    public var overallStatus: AnonymousBenchmarkStatus
    public var overallPeerPercentile: Int
    public var comparisons: [AnonymousBenchmarkCategoryComparison]

    public init(
        profile: AnonymousBenchmarkProfile,
        totalUserExpense: Decimal,
        totalBenchmarkExpense: Decimal,
        overallStatus: AnonymousBenchmarkStatus,
        overallPeerPercentile: Int,
        comparisons: [AnonymousBenchmarkCategoryComparison]
    ) {
        self.profile = profile
        self.totalUserExpense = totalUserExpense
        self.totalBenchmarkExpense = totalBenchmarkExpense
        self.overallStatus = overallStatus
        self.overallPeerPercentile = overallPeerPercentile
        self.comparisons = comparisons
    }

    public var topComparisons: [AnonymousBenchmarkCategoryComparison] {
        comparisons
            .filter { $0.userAmount > 0 || $0.benchmarkAmount > 0 }
            .sorted {
                let lhsDifference = abs(NSDecimalNumber(decimal: $0.differenceAmount).doubleValue)
                let rhsDifference = abs(NSDecimalNumber(decimal: $1.differenceAmount).doubleValue)
                if lhsDifference == rhsDifference {
                    return $0.category.id < $1.category.id
                }

                return lhsDifference > rhsDifference
            }
    }
}
