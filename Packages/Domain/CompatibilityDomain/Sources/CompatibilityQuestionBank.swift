import Foundation

public enum CompatibilityQuestionBank {
    public static let defaultQuestions: [CompatibilityQuestion] = [
        question(.spendingStyle, idSuffix: "000000018101"),
        question(.riskTolerance, idSuffix: "000000018102"),
        question(.debtAttitude, idSuffix: "000000018103"),
        question(.splittingApproach, idSuffix: "000000018104"),
        question(.familySupport, idSuffix: "000000018105"),
        question(.futureGoals, idSuffix: "000000018106"),
    ]

    private static func question(
        _ dimension: CompatibilityDimension,
        idSuffix: String
    ) -> CompatibilityQuestion {
        CompatibilityQuestion(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(idSuffix)") ?? UUID(),
            dimension: dimension,
            textKey: "compatibility.question.\(dimension.rawValue).text",
            options: [
                option(dimension, index: 0, value: 0),
                option(dimension, index: 1, value: 0.33),
                option(dimension, index: 2, value: 0.67),
                option(dimension, index: 3, value: 1),
            ]
        )
    }

    private static func option(
        _ dimension: CompatibilityDimension,
        index: Int,
        value: Double
    ) -> CompatibilityOption {
        CompatibilityOption(
            textKey: "compatibility.question.\(dimension.rawValue).option.\(index)",
            compatibilityValue: value
        )
    }
}
