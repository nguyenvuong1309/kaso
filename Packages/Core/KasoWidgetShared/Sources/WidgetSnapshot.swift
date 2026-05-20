import Foundation

/// Aggregated, PII-free summary the main app publishes for widgets and Live
/// Activities to render. The widget extension only ever reads from this
/// snapshot — it never touches the encrypted transaction store directly.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public static let appGroupID = "group.com.vuongnguyen.kaso"
    public static let storageKey = "widget.snapshot.v1"

    public var totalSpentToday: Decimal
    public var monthlyBudgetLimit: Decimal
    public var monthlyBudgetSpent: Decimal
    public var transactionCountToday: Int
    public var currencyCode: String
    public var updatedAt: Date

    public init(
        totalSpentToday: Decimal,
        monthlyBudgetLimit: Decimal,
        monthlyBudgetSpent: Decimal,
        transactionCountToday: Int,
        currencyCode: String,
        updatedAt: Date
    ) {
        self.totalSpentToday = totalSpentToday
        self.monthlyBudgetLimit = monthlyBudgetLimit
        self.monthlyBudgetSpent = monthlyBudgetSpent
        self.transactionCountToday = transactionCountToday
        self.currencyCode = currencyCode
        self.updatedAt = updatedAt
    }

    public static let placeholder = WidgetSnapshot(
        totalSpentToday: 0,
        monthlyBudgetLimit: 0,
        monthlyBudgetSpent: 0,
        transactionCountToday: 0,
        currencyCode: "VND",
        updatedAt: Date(timeIntervalSinceReferenceDate: 0)
    )

    public var budgetRemaining: Decimal {
        max(0, monthlyBudgetLimit - monthlyBudgetSpent)
    }

    public var budgetUsedFraction: Double {
        guard monthlyBudgetLimit > 0 else { return 0 }
        let used = NSDecimalNumber(decimal: monthlyBudgetSpent).doubleValue
        let limit = NSDecimalNumber(decimal: monthlyBudgetLimit).doubleValue
        return max(0, min(1, used / limit))
    }
}

public enum WidgetSnapshotStore {
    public static func load(from defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.appGroupID)) -> WidgetSnapshot {
        guard
            let defaults,
            let data = defaults.data(forKey: WidgetSnapshot.storageKey)
        else { return .placeholder }
        let decoder = JSONDecoder()
        return (try? decoder.decode(WidgetSnapshot.self, from: data)) ?? .placeholder
    }

    public static func save(_ snapshot: WidgetSnapshot, into defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.appGroupID)) {
        guard let defaults else { return }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: WidgetSnapshot.storageKey)
    }
}
