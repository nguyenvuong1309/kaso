import Foundation

public enum SleepCorrelationAnalyzer {
    public static func compute(dataPoints: [SleepSpendingDataPoint]) -> SleepCorrelationInsight {
        guard dataPoints.count >= SleepCorrelationInsight.minimumDataPoints else {
            return SleepCorrelationInsight(
                correlationCoefficient: 0,
                significance: .insufficient,
                pattern: nil,
                dataPointCount: dataPoints.count,
                insights: [
                    "Cần ít nhất 21 ngày dữ liệu ngủ và chi tiêu để phân tích đáng tin cậy.",
                ]
            )
        }

        let coefficient = pearsonCoefficient(dataPoints)
        let significance = significance(for: coefficient)
        let pattern = pattern(for: coefficient, dataPoints: dataPoints)

        return SleepCorrelationInsight(
            correlationCoefficient: coefficient,
            significance: significance,
            pattern: pattern,
            dataPointCount: dataPoints.count,
            insights: insightTexts(
                coefficient: coefficient,
                significance: significance,
                pattern: pattern
            )
        )
    }
}

private extension SleepCorrelationAnalyzer {
    static func pearsonCoefficient(_ points: [SleepSpendingDataPoint]) -> Double {
        let sleepValues = points.map(\.sleepHours)
        let spendingValues = points.map { NSDecimalNumber(decimal: $0.totalSpending).doubleValue }
        let sleepAverage = average(sleepValues)
        let spendingAverage = average(spendingValues)

        var numerator = 0.0
        var sleepVariance = 0.0
        var spendingVariance = 0.0

        for index in points.indices {
            let sleepDelta = sleepValues[index] - sleepAverage
            let spendingDelta = spendingValues[index] - spendingAverage
            numerator += sleepDelta * spendingDelta
            sleepVariance += sleepDelta * sleepDelta
            spendingVariance += spendingDelta * spendingDelta
        }

        let denominator = sqrt(sleepVariance * spendingVariance)
        guard denominator > 0 else {
            return 0
        }
        return max(-1, min(1, numerator / denominator))
    }

    static func average(_ values: [Double]) -> Double {
        guard values.isEmpty == false else {
            return 0
        }
        return values.reduce(0, +) / Double(values.count)
    }

    static func significance(for coefficient: Double) -> StatisticalSignificance {
        let magnitude = abs(coefficient)
        if magnitude < 0.2 {
            return .weak
        } else if magnitude < 0.45 {
            return .moderate
        } else {
            return .strong
        }
    }

    static func pattern(
        for coefficient: Double,
        dataPoints: [SleepSpendingDataPoint]
    ) -> SpendingPattern {
        guard abs(coefficient) >= 0.2 else {
            return .noSignificantPattern
        }

        let poorAverage = averageSpending(
            dataPoints.filter { $0.sleepQuality == .poor }
        )
        let goodAverage = averageSpending(
            dataPoints.filter { $0.sleepQuality == .good }
        )
        let difference = abs(poorAverage - goodAverage)

        if coefficient < 0 {
            return .lessSleepMoreSpending(avgDiff: difference)
        } else {
            return .moreSleepLessSpending(avgDiff: difference)
        }
    }

    static func averageSpending(_ points: [SleepSpendingDataPoint]) -> Decimal {
        guard points.isEmpty == false else {
            return 0
        }
        return points.reduce(Decimal(0)) { $0 + $1.totalSpending } / Decimal(points.count)
    }

    static func insightTexts(
        coefficient: Double,
        significance: StatisticalSignificance,
        pattern: SpendingPattern
    ) -> [String] {
        switch pattern {
        case .lessSleepMoreSpending:
            [
                "Những ngày ngủ ít có xu hướng đi kèm mức chi cao hơn.",
                "Hãy dùng kết quả này như tín hiệu để kiểm tra thói quen mua bốc đồng sau đêm thiếu ngủ.",
            ]
        case .moreSleepLessSpending:
            [
                "Dữ liệu cho thấy khi ngủ nhiều hơn, chi tiêu có xu hướng giảm.",
                "Tương quan \(significance.rawValue) với hệ số \(coefficient.formatted(.number.precision(.fractionLength(2)))).",
            ]
        case .lessSleepMoreImpulse:
            [
                "Một số danh mục có dấu hiệu tăng sau ngày ngủ kém.",
            ]
        case .noSignificantPattern:
            [
                "Chưa thấy tương quan đáng kể giữa giấc ngủ và chi tiêu.",
            ]
        }
    }
}
