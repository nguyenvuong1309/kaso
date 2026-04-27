import Foundation

public enum CompatibilityCalculator {
    public static let conflictThreshold: Double = 40
    private static let maximumOppositePenalty: Double = 70

    public static func calculate(
        questions: [CompatibilityQuestion] = CompatibilityQuestionBank.defaultQuestions,
        userAnswers: [CompatibilityAnswer],
        partnerAnswers: [CompatibilityAnswer],
        generatedAt: Date = Date()
    ) -> CompatibilityResult {
        let userAnswersByQuestion = Dictionary(uniqueKeysWithValues: userAnswers.map {
            ($0.questionId, $0)
        })
        let partnerAnswersByQuestion = Dictionary(uniqueKeysWithValues: partnerAnswers.map {
            ($0.questionId, $0)
        })

        let dimensionScores = scoresByDimension(
            questions: questions,
            userAnswersByQuestion: userAnswersByQuestion,
            partnerAnswersByQuestion: partnerAnswersByQuestion
        )
        let overallScore = averageScore(dimensionScores)
        let compatibilityType = CompatibilityType(score: overallScore)
        let conflicts = conflictInsights(from: dimensionScores)

        return CompatibilityResult(
            overallScore: overallScore,
            dimensionScores: dimensionScores,
            compatibilityType: compatibilityType,
            highlightedConflicts: conflicts,
            conversationStarters: conversationStarters(
                for: compatibilityType,
                conflicts: conflicts
            ),
            generatedAt: generatedAt
        )
    }

    private static func scoresByDimension(
        questions: [CompatibilityQuestion],
        userAnswersByQuestion: [UUID: CompatibilityAnswer],
        partnerAnswersByQuestion: [UUID: CompatibilityAnswer]
    ) -> [CompatibilityDimension: Double] {
        var scores: [CompatibilityDimension: Double] = [:]

        for dimension in CompatibilityDimension.allCases {
            let dimensionQuestions = questions.filter { $0.dimension == dimension }
            var weightedScore = 0.0
            var totalWeight = 0.0

            for question in dimensionQuestions {
                guard
                    let userAnswer = userAnswersByQuestion[question.id],
                    let partnerAnswer = partnerAnswersByQuestion[question.id],
                    let userValue = selectedValue(userAnswer, in: question),
                    let partnerValue = selectedValue(partnerAnswer, in: question)
                else {
                    continue
                }

                let distance = min(abs(userValue - partnerValue), 1)
                let questionScore = max(0, 100 - distance * maximumOppositePenalty)
                weightedScore += questionScore * question.weight
                totalWeight += question.weight
            }

            scores[dimension] = totalWeight > 0 ? weightedScore / totalWeight : 0
        }

        return scores
    }

    private static func selectedValue(
        _ answer: CompatibilityAnswer,
        in question: CompatibilityQuestion
    ) -> Double? {
        guard question.options.indices.contains(answer.selectedOptionIndex) else {
            return nil
        }
        return question.options[answer.selectedOptionIndex].compatibilityValue
    }

    private static func averageScore(
        _ scores: [CompatibilityDimension: Double]
    ) -> Double {
        guard scores.isEmpty == false else {
            return 0
        }
        return scores.values.reduce(0, +) / Double(scores.count)
    }

    private static func conflictInsights(
        from scores: [CompatibilityDimension: Double]
    ) -> [ConflictInsight] {
        CompatibilityDimension.allCases.compactMap { dimension in
            guard let score = scores[dimension], score < conflictThreshold else {
                return nil
            }
            return ConflictInsight(
                dimension: dimension,
                score: score,
                titleKey: "compatibility.conflict.\(dimension.rawValue).title",
                descriptionKey: "compatibility.conflict.\(dimension.rawValue).description"
            )
        }
    }

    static func conversationStarters(
        for type: CompatibilityType,
        conflicts: [ConflictInsight]
    ) -> [String] {
        let conflictStarter = conflicts.first.map {
            "compatibility.starter.conflict.\($0.dimension.rawValue)"
        }
        return [
            conflictStarter,
            "compatibility.starter.\(type.rawValue).first",
            "compatibility.starter.\(type.rawValue).second",
        ].compactMap { $0 }
    }
}
