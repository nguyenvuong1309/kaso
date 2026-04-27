import Foundation

public struct CompatibilityOption: Codable, Equatable, Sendable {
    public var textKey: String
    public var compatibilityValue: Double

    public init(textKey: String, compatibilityValue: Double) {
        self.textKey = textKey
        self.compatibilityValue = compatibilityValue
    }
}

public struct CompatibilityQuestion: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var dimension: CompatibilityDimension
    public var textKey: String
    public var options: [CompatibilityOption]
    public var weight: Double

    public init(
        id: UUID = UUID(),
        dimension: CompatibilityDimension,
        textKey: String,
        options: [CompatibilityOption],
        weight: Double = 1
    ) {
        self.id = id
        self.dimension = dimension
        self.textKey = textKey
        self.options = options
        self.weight = weight
    }
}

public enum CompatibilityRespondent: String, Codable, Equatable, Sendable {
    case user
    case partner
}

public struct CompatibilityAnswer: Codable, Equatable, Sendable {
    public var questionId: UUID
    public var selectedOptionIndex: Int
    public var respondent: CompatibilityRespondent

    public init(
        questionId: UUID,
        selectedOptionIndex: Int,
        respondent: CompatibilityRespondent
    ) {
        self.questionId = questionId
        self.selectedOptionIndex = selectedOptionIndex
        self.respondent = respondent
    }
}

public struct ConflictInsight: Identifiable, Codable, Equatable, Sendable {
    public var dimension: CompatibilityDimension
    public var score: Double
    public var titleKey: String
    public var descriptionKey: String

    public init(
        dimension: CompatibilityDimension,
        score: Double,
        titleKey: String,
        descriptionKey: String
    ) {
        self.dimension = dimension
        self.score = score
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
    }

    public var id: String {
        dimension.rawValue
    }
}

public struct CompatibilityResult: Codable, Equatable, Sendable {
    public var overallScore: Double
    public var dimensionScores: [CompatibilityDimension: Double]
    public var compatibilityType: CompatibilityType
    public var highlightedConflicts: [ConflictInsight]
    public var conversationStarters: [String]
    public var generatedAt: Date

    public init(
        overallScore: Double,
        dimensionScores: [CompatibilityDimension: Double],
        compatibilityType: CompatibilityType,
        highlightedConflicts: [ConflictInsight],
        conversationStarters: [String],
        generatedAt: Date
    ) {
        self.overallScore = overallScore
        self.dimensionScores = dimensionScores
        self.compatibilityType = compatibilityType
        self.highlightedConflicts = highlightedConflicts
        self.conversationStarters = conversationStarters
        self.generatedAt = generatedAt
    }
}

public enum CompatibilityType: String, CaseIterable, Codable, Equatable, Sendable {
    case perfectMatch
    case strongFoundation
    case workInProgress
    case oppositesAttract
    case needsAlignment

    public init(score: Double) {
        switch score {
        case 85...:
            self = .perfectMatch
        case 70..<85:
            self = .strongFoundation
        case 50..<70:
            self = .workInProgress
        case 30..<50:
            self = .oppositesAttract
        default:
            self = .needsAlignment
        }
    }

    public var titleKey: String {
        "compatibility.type.\(rawValue).title"
    }

    public var descriptionKey: String {
        "compatibility.type.\(rawValue).description"
    }

    public var colorName: String {
        switch self {
        case .perfectMatch:
            "green"
        case .strongFoundation:
            "mint"
        case .workInProgress:
            "blue"
        case .oppositesAttract:
            "orange"
        case .needsAlignment:
            "purple"
        }
    }
}
