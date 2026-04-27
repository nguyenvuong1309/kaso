import Foundation
import Testing
import TransactionDomain
@testable import SleepCorrelationDomain

@Test("significance is insufficient under twenty one points")
func significanceIsInsufficientUnderTwentyOnePoints() {
    let points = (0..<20).map {
        point(day: $0, sleepHours: 6, spending: 100_000)
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.significance == .insufficient)
    #expect(insight.dataPointCount == 20)
    #expect(insight.pattern == nil)
}

@Test("negative coefficient detects less sleep more spending")
func negativeCoefficientDetectsLessSleepMoreSpending() {
    let points = (0..<30).map { index in
        point(
            day: index,
            sleepHours: 4 + Double(index) * 0.15,
            spending: Decimal(600_000 - index * 12_000)
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.correlationCoefficient < -0.9)
    #expect(insight.significance == .strong)
    #expect(isLessSleepMoreSpending(insight.pattern))
}

@Test("weak coefficient reports no significant pattern")
func weakCoefficientReportsNoSignificantPattern() {
    let points = (0..<30).map { index in
        point(
            day: index,
            sleepHours: Double(6 + index % 3),
            spending: Decimal(100_000 + (index % 2) * 5_000)
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.significance == .weak)
    #expect(insight.pattern == .noSignificantPattern)
}

@Test("builder combines sleep samples with spending by day")
func builderCombinesSleepSamplesWithSpendingByDay() {
    let calendar = Calendar(identifier: .gregorian)
    let day = date(year: 2026, month: 4, day: 2)
    let points = SleepSpendingDataBuilder.makeDataPoints(
        sleepSamples: [
            SleepSample(date: day, hours: 5.5),
        ],
        transactions: [
            Transaction(
                amount: 80_000,
                kind: .expense,
                category: .food,
                occurredAt: day
            ),
            Transaction(
                amount: 20_000_000,
                kind: .income,
                category: .salary,
                occurredAt: day
            ),
        ],
        calendar: calendar
    )

    #expect(points.count == 1)
    #expect(points.first?.totalSpending == 80_000)
    #expect(points.first?.transactionCount == 1)
    #expect(points.first?.sleepQuality == .poor)
}

private func point(day: Int, sleepHours: Double, spending: Decimal) -> SleepSpendingDataPoint {
    SleepSpendingDataPoint(
        date: Date(timeIntervalSinceReferenceDate: Double(day) * 86_400),
        sleepHours: sleepHours,
        totalSpending: spending,
        transactionCount: 1,
        categories: [
            CategorySpending(category: .food, amount: spending),
        ]
    )
}

private func isLessSleepMoreSpending(_ pattern: SpendingPattern?) -> Bool {
    guard case .lessSleepMoreSpending = pattern else {
        return false
    }
    return true
}

private func date(year: Int, month: Int, day: Int) -> Date {
    DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: year,
        month: month,
        day: day
    ).date ?? Date(timeIntervalSinceReferenceDate: 0)
}
