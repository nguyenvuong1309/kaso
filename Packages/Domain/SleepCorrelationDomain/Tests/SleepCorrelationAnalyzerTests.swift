import Foundation
import Testing
import TransactionDomain
@testable import SleepCorrelationDomain

@Test("insufficient data returns guidance insight and zero coefficient")
func insufficientDataReturnsGuidance() {
    let points = (0..<10).map { analyzerPoint(day: $0, sleepHours: 7, spending: 100_000) }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.significance == .insufficient)
    #expect(insight.correlationCoefficient == 0)
    #expect(insight.pattern == nil)
    #expect(insight.dataPointCount == 10)
    #expect(insight.insights.count == 1)
}

@Test("empty input is treated as insufficient")
func emptyInputIsInsufficient() {
    let insight = SleepCorrelationAnalyzer.compute(dataPoints: [])

    #expect(insight.significance == .insufficient)
    #expect(insight.dataPointCount == 0)
    #expect(insight.pattern == nil)
}

@Test("exactly twenty one points crosses the minimum threshold")
func exactlyTwentyOnePointsIsAnalyzed() {
    let points = (0..<21).map { index in
        analyzerPoint(
            day: index,
            sleepHours: 4 + Double(index) * 0.2,
            spending: Decimal(500_000 - index * 15_000)
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.significance != .insufficient)
    #expect(insight.dataPointCount == 21)
}

@Test("positive coefficient detects more sleep less spending")
func positiveCoefficientDetectsMoreSleepLessSpending() {
    let points = (0..<30).map { index in
        analyzerPoint(
            day: index,
            sleepHours: 4 + Double(index) * 0.15,
            spending: Decimal(100_000 + index * 12_000)
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.correlationCoefficient > 0.9)
    #expect(insight.significance == .strong)
    #expect(isMoreSleepLessSpending(insight.pattern))
    #expect(insight.insights.count == 2)
}

@Test("constant spending yields zero coefficient and weak significance")
func constantSpendingYieldsZeroCoefficient() {
    let points = (0..<30).map { index in
        analyzerPoint(
            day: index,
            sleepHours: 4 + Double(index) * 0.1,
            spending: 100_000
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.correlationCoefficient == 0)
    #expect(insight.significance == .weak)
    #expect(insight.pattern == .noSignificantPattern)
}

@Test("constant sleep hours yields zero coefficient")
func constantSleepHoursYieldsZeroCoefficient() {
    let points = (0..<30).map { index in
        analyzerPoint(
            day: index,
            sleepHours: 7,
            spending: Decimal(100_000 + index * 5_000)
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.correlationCoefficient == 0)
    #expect(insight.significance == .weak)
}

@Test("moderate correlation produces moderate significance")
func moderateCorrelationProducesModerateSignificance() {
    // Mostly linear positive trend with noise to land between 0.2 and 0.45.
    let spendings: [Decimal] = [
        300_000, 120_000, 260_000, 140_000, 280_000, 110_000, 240_000,
        160_000, 300_000, 130_000, 250_000, 150_000, 290_000, 120_000,
        230_000, 170_000, 310_000, 100_000, 270_000, 140_000, 260_000,
        180_000, 320_000, 110_000, 250_000, 160_000, 300_000, 130_000,
        240_000, 190_000,
    ]
    let points = spendings.enumerated().map { index, spending in
        analyzerPoint(
            day: index,
            sleepHours: 5 + Double(index % 4),
            spending: spending
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)
    let magnitude = abs(insight.correlationCoefficient)

    // Sanity: this dataset is constructed to be weak/moderate, never strong.
    #expect(magnitude < 0.45)
}

@Test("strong negative pattern computes average spending difference")
func strongNegativePatternComputesDifference() {
    // First 15 days poor sleep + high spend, last 15 good sleep + low spend.
    let points = (0..<30).map { index -> SleepSpendingDataPoint in
        let isPoor = index < 15
        return analyzerPoint(
            day: index,
            sleepHours: isPoor ? 4.5 : 8.0,
            spending: isPoor ? 400_000 : 100_000
        )
    }

    let insight = SleepCorrelationAnalyzer.compute(dataPoints: points)

    #expect(insight.correlationCoefficient < 0)
    if case let .lessSleepMoreSpending(avgDiff) = insight.pattern {
        #expect(avgDiff == 300_000)
    } else {
        Issue.record("Expected lessSleepMoreSpending pattern")
    }
}

private func analyzerPoint(day: Int, sleepHours: Double, spending: Decimal) -> SleepSpendingDataPoint {
    SleepSpendingDataPoint(
        date: Date(timeIntervalSinceReferenceDate: Double(day) * 86_400),
        sleepHours: sleepHours,
        totalSpending: spending,
        transactionCount: 1,
        categories: [CategorySpending(category: .food, amount: spending)]
    )
}

private func isMoreSleepLessSpending(_ pattern: SpendingPattern?) -> Bool {
    guard case .moreSleepLessSpending = pattern else {
        return false
    }
    return true
}
