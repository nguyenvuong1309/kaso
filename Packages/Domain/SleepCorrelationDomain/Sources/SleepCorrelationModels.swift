import Foundation
import TransactionDomain

public struct SleepSample: Codable, Equatable, Sendable {
    public var date: Date
    public var hours: Double

    public init(date: Date, hours: Double) {
        self.date = date
        self.hours = hours
    }
}

public enum SleepQuality: String, Codable, Equatable, Sendable {
    case poor
    case fair
    case good

    public init(hours: Double) {
        if hours < 6 {
            self = .poor
        } else if hours < 7 {
            self = .fair
        } else {
            self = .good
        }
    }

    public var titleKey: String {
        "sleep.quality.\(rawValue)"
    }
}

public struct CategorySpending: Codable, Equatable, Sendable {
    public var category: TransactionCategory
    public var amount: Decimal

    public init(category: TransactionCategory, amount: Decimal) {
        self.category = category
        self.amount = amount
    }
}

public struct SleepSpendingDataPoint: Identifiable, Codable, Equatable, Sendable {
    public var date: Date
    public var sleepHours: Double
    public var sleepQuality: SleepQuality
    public var totalSpending: Decimal
    public var transactionCount: Int
    public var categories: [CategorySpending]

    public var id: Date { date }

    public init(
        date: Date,
        sleepHours: Double,
        sleepQuality: SleepQuality? = nil,
        totalSpending: Decimal,
        transactionCount: Int,
        categories: [CategorySpending]
    ) {
        self.date = date
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality ?? SleepQuality(hours: sleepHours)
        self.totalSpending = totalSpending
        self.transactionCount = transactionCount
        self.categories = categories
    }
}

public enum StatisticalSignificance: String, Codable, Equatable, Sendable {
    case insufficient
    case weak
    case moderate
    case strong
}

public enum SpendingPattern: Codable, Equatable, Sendable {
    case moreSleepLessSpending(avgDiff: Decimal)
    case lessSleepMoreSpending(avgDiff: Decimal)
    case lessSleepMoreImpulse(categories: [TransactionCategory])
    case noSignificantPattern
}

public struct SleepCorrelationInsight: Codable, Equatable, Sendable {
    public static let minimumDataPoints = 21
    public static let disclaimer = "Phân tích này chỉ là tương quan cá nhân trên thiết bị, không phải lời khuyên y tế hoặc tài chính."

    public let correlationCoefficient: Double
    public let significance: StatisticalSignificance
    public let pattern: SpendingPattern?
    public let dataPointCount: Int
    public let insights: [String]
    public let disclaimer: String

    public init(
        correlationCoefficient: Double,
        significance: StatisticalSignificance,
        pattern: SpendingPattern?,
        dataPointCount: Int,
        insights: [String],
        disclaimer: String = SleepCorrelationInsight.disclaimer
    ) {
        self.correlationCoefficient = correlationCoefficient
        self.significance = significance
        self.pattern = pattern
        self.dataPointCount = dataPointCount
        self.insights = insights
        self.disclaimer = disclaimer
    }
}

public enum SleepCorrelationPeriod: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case lastThirtyDays
    case lastNinetyDays
    case all

    public var id: String { rawValue }

    public var titleKey: String {
        "sleep.period.\(rawValue)"
    }
}
