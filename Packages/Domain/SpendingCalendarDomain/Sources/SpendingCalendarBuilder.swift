import Foundation

public struct SpendingCalendarTransaction: Equatable, Sendable {
    public var amount: Decimal
    public var occurredAt: Date
    public var label: String
    public var category: String?

    public init(amount: Decimal, occurredAt: Date, label: String, category: String? = nil) {
        self.amount = amount
        self.occurredAt = occurredAt
        self.label = label
        self.category = category
    }
}

public struct SpendingCalendarRecurringEvent: Equatable, Sendable {
    public var label: String
    public var amount: Decimal
    public var firstOccurrence: Date
    public var intervalDays: Int
    public var category: String?

    public init(
        label: String,
        amount: Decimal,
        firstOccurrence: Date,
        intervalDays: Int,
        category: String? = nil
    ) {
        self.label = label
        self.amount = amount
        self.firstOccurrence = firstOccurrence
        self.intervalDays = max(intervalDays, 1)
        self.category = category
    }
}

public enum SpendingCalendarBuilder {
    public static func build(
        month: Date,
        transactions: [SpendingCalendarTransaction],
        recurringEvents: [SpendingCalendarRecurringEvent],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> SpendingCalendarMonth {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: month),
            let dayCount = calendar.range(of: .day, in: .month, for: month)?.count,
            let monthStart = calendar.dateInterval(of: .month, for: month)?.start
        else {
            return .empty
        }

        let dayDates: [Date] = (0 ..< dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monthStart)
        }

        let actualByDay = Dictionary(grouping: transactions) {
            calendar.startOfDay(for: $0.occurredAt)
        }

        let forecastByDay = forecastEvents(
            in: monthInterval,
            recurring: recurringEvents,
            calendar: calendar
        )

        let todayStart = calendar.startOfDay(for: referenceDate)
        let pastDays = dayDates.filter { $0 <= todayStart }
        let actualTotal = pastDays.reduce(Decimal(0)) { partial, day in
            let items = actualByDay[day] ?? []
            return partial + items.reduce(Decimal(0)) { $0 + $1.amount }
        }
        let activePastDays = pastDays.filter { (actualByDay[$0]?.isEmpty == false) }
        let average = activePastDays.isEmpty
            ? 0
            : actualTotal / Decimal(activePastDays.count)
        let averageDouble = NSDecimalNumber(decimal: average).doubleValue

        var days: [DailySpending] = []
        var forecastTotal = Decimal(0)

        for day in dayDates {
            let isPastOrToday = day <= todayStart
            if isPastOrToday {
                let txs = actualByDay[day] ?? []
                let total = txs.reduce(Decimal(0)) { $0 + $1.amount }
                let items = txs.map {
                    DailySpendingItem(label: $0.label, amount: $0.amount, category: $0.category)
                }
                let delta: Double = {
                    guard averageDouble > 0 else {
                        return 0
                    }
                    let totalDouble = NSDecimalNumber(decimal: total).doubleValue
                    return (totalDouble - averageDouble) / averageDouble
                }()
                days.append(
                    DailySpending(
                        date: day,
                        total: total,
                        kind: .actual,
                        items: items,
                        deltaFromAverage: delta
                    )
                )
            } else {
                let forecastItems = forecastByDay[day] ?? []
                let total = forecastItems.reduce(Decimal(0)) { $0 + $1.amount }
                forecastTotal += total
                days.append(
                    DailySpending(
                        date: day,
                        total: total,
                        kind: .forecast,
                        items: forecastItems,
                        deltaFromAverage: 0
                    )
                )
            }
        }

        let topDay = days
            .filter { $0.kind == .actual && $0.total > 0 }
            .max { $0.total < $1.total }

        return SpendingCalendarMonth(
            month: monthStart,
            days: days,
            actualTotal: actualTotal,
            forecastTotal: forecastTotal,
            averageDailySpending: average,
            topDay: topDay
        )
    }

    private static func forecastEvents(
        in interval: DateInterval,
        recurring: [SpendingCalendarRecurringEvent],
        calendar: Calendar
    ) -> [Date: [DailySpendingItem]] {
        var result: [Date: [DailySpendingItem]] = [:]
        for event in recurring {
            var occurrence = event.firstOccurrence
            // Roll forward to first occurrence in interval if needed.
            while occurrence < interval.start {
                guard let next = calendar.date(byAdding: .day, value: event.intervalDays, to: occurrence) else {
                    break
                }
                occurrence = next
            }
            while occurrence < interval.end {
                let day = calendar.startOfDay(for: occurrence)
                let item = DailySpendingItem(
                    label: event.label,
                    amount: event.amount,
                    category: event.category
                )
                result[day, default: []].append(item)
                guard let next = calendar.date(byAdding: .day, value: event.intervalDays, to: occurrence) else {
                    break
                }
                occurrence = next
            }
        }
        return result
    }
}
