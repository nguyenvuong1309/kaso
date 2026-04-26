import Foundation
import TransactionDomain

public struct SubscriptionDetector: Sendable {
    public var configuration: SubscriptionDetectionConfiguration

    public init(configuration: SubscriptionDetectionConfiguration = SubscriptionDetectionConfiguration()) {
        self.configuration = configuration
    }

    public func detect(
        from transactions: [Transaction],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> SubscriptionDetectionResult {
        let groupedTransactions = Dictionary(grouping: eligibleTransactions(from: transactions)) { transaction in
            SubscriptionMerchantExtractor.merchant(from: transaction).normalizedKey
        }

        let subscriptions = groupedTransactions.values
            .compactMap { group in
                detectedSubscription(
                    from: group,
                    referenceDate: referenceDate,
                    calendar: calendar
                )
            }
            .sorted { lhs, rhs in
                if lhs.monthlyAmount == rhs.monthlyAmount {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }

                return lhs.monthlyAmount > rhs.monthlyAmount
            }

        return SubscriptionDetectionResult(subscriptions: subscriptions)
    }

    private func eligibleTransactions(from transactions: [Transaction]) -> [Transaction] {
        transactions.filter { transaction in
            transaction.kind == .expense && transaction.amount > Decimal(0)
        }
    }

    private func detectedSubscription(
        from transactions: [Transaction],
        referenceDate: Date,
        calendar: Calendar
    ) -> DetectedSubscription? {
        let sortedTransactions = transactions.sorted { lhs, rhs in
            lhs.occurredAt < rhs.occurredAt
        }

        guard sortedTransactions.count >= configuration.minimumOccurrences,
              amountsAreStable(sortedTransactions.map(\.amount)),
              let interval = inferredInterval(from: sortedTransactions.map(\.occurredAt), calendar: calendar),
              let lastTransaction = sortedTransactions.last else {
            return nil
        }

        let merchant = SubscriptionMerchantExtractor.merchant(from: lastTransaction)
        let averageAmount = averageAmount(from: sortedTransactions)
        let monthlyAmount = interval.monthlyEquivalent(for: averageAmount)
        let nextBillingDate = interval.nextDate(
            after: lastTransaction.occurredAt,
            referenceDate: referenceDate,
            calendar: calendar
        )

        return DetectedSubscription(
            merchant: merchant,
            category: lastTransaction.category,
            interval: interval,
            averageAmount: averageAmount,
            monthlyAmount: monthlyAmount,
            lastBillingDate: lastTransaction.occurredAt,
            nextBillingDate: nextBillingDate,
            transactionIDs: sortedTransactions.map(\.id),
            confidence: confidence(for: sortedTransactions, interval: interval, calendar: calendar)
        )
    }

    private func averageAmount(from transactions: [Transaction]) -> Decimal {
        let total = transactions.reduce(Decimal(0)) { partialResult, transaction in
            partialResult + transaction.amount
        }

        return total / Decimal(transactions.count)
    }

    private func amountsAreStable(_ amounts: [Decimal]) -> Bool {
        guard !amounts.isEmpty else {
            return false
        }

        let total = amounts.reduce(Decimal(0), +)
        let average = total / Decimal(amounts.count)

        guard average > Decimal(0) else {
            return false
        }

        let allowedDeviation = average * configuration.amountVarianceTolerance

        return amounts.allSatisfy { amount in
            absolute(amount - average) <= allowedDeviation
        }
    }

    private func inferredInterval(from dates: [Date], calendar: Calendar) -> SubscriptionInterval? {
        let sortedDates = dates.sorted()
        let gapCount = sortedDates.count - 1

        guard gapCount > 0 else {
            return nil
        }

        let minimumMatches = max(
            1,
            Int((Double(gapCount) * configuration.minimumIntervalMatchRatio).rounded(.up))
        )

        return SubscriptionInterval.allCases
            .map { interval in
                IntervalCandidate(
                    interval: interval,
                    matchCount: matchCount(for: interval, dates: sortedDates, calendar: calendar)
                )
            }
            .filter { candidate in
                candidate.matchCount >= minimumMatches
            }
            .sorted { lhs, rhs in
                if lhs.matchCount == rhs.matchCount {
                    return lhs.interval.priority < rhs.interval.priority
                }

                return lhs.matchCount > rhs.matchCount
            }
            .first?
            .interval
    }

    private func matchCount(
        for interval: SubscriptionInterval,
        dates: [Date],
        calendar: Calendar
    ) -> Int {
        zip(dates, dates.dropFirst()).filter { startDate, endDate in
            interval.matchesGap(from: startDate, to: endDate, calendar: calendar)
        }.count
    }

    private func confidence(
        for transactions: [Transaction],
        interval: SubscriptionInterval,
        calendar: Calendar
    ) -> Double {
        let dates = transactions.map(\.occurredAt).sorted()
        let gapCount = max(1, dates.count - 1)
        let intervalConsistency = Double(matchCount(for: interval, dates: dates, calendar: calendar)) / Double(gapCount)
        let occurrenceScore = min(Double(transactions.count) / 4, 1)

        return min(1, (intervalConsistency * 0.75) + (occurrenceScore * 0.25))
    }

    private func absolute(_ value: Decimal) -> Decimal {
        if value < Decimal(0) {
            return -value
        }

        return value
    }
}

private struct IntervalCandidate: Equatable, Sendable {
    var interval: SubscriptionInterval
    var matchCount: Int
}

private extension SubscriptionInterval {
    var priority: Int {
        switch self {
        case .weekly:
            0
        case .monthly:
            1
        case .yearly:
            2
        }
    }
}
