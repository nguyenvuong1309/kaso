import Foundation

public enum SavingGoalValidationError: String, Error, Codable, Equatable, Sendable {
    case nameRequired
    case targetAmountMustBePositive
    case currentAmountCannotBeNegative
    case currentAmountCannotExceedTargetAmount
    case deadlineMustBeInFuture
}

public struct SavingGoalDraft: Codable, Equatable, Sendable {
    public var name: String
    public var targetAmount: Decimal
    public var currentAmount: Decimal
    public var deadline: Date
    public var imageIdentifier: String?

    public init(
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date,
        imageIdentifier: String? = nil
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.imageIdentifier = imageIdentifier
    }

    public func validationErrors(
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> [SavingGoalValidationError] {
        var errors: [SavingGoalValidationError] = []

        if trimmedName.isEmpty {
            errors.append(.nameRequired)
        }

        if targetAmount <= 0 {
            errors.append(.targetAmountMustBePositive)
        }

        if currentAmount < 0 {
            errors.append(.currentAmountCannotBeNegative)
        }

        if targetAmount > 0 && currentAmount > targetAmount {
            errors.append(.currentAmountCannotExceedTargetAmount)
        }

        if calendar.compare(deadline, to: date, toGranularity: .day) != .orderedDescending {
            errors.append(.deadlineMustBeInFuture)
        }

        return errors
    }

    public func validated(
        id: @autoclosure () -> UUID = UUID(),
        createdAt: Date = Date(),
        calendar: Calendar = .current
    ) throws -> SavingGoal {
        let errors = validationErrors(asOf: createdAt, calendar: calendar)
        if let firstError = errors.first {
            throw firstError
        }

        return SavingGoal(
            id: id(),
            name: trimmedName,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: deadline,
            createdAt: createdAt,
            imageIdentifier: imageIdentifier
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
