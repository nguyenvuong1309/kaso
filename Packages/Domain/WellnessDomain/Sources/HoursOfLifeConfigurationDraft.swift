import Foundation

public enum HoursOfLifeConfigurationValidationError: String, Error, Codable, Equatable, Sendable {
    case incomeMustBePositive
    case workHoursMustBePositive
    case workHoursTooHigh
}

public struct HoursOfLifeConfigurationDraft: Equatable, Sendable {
    public static let maxMonthlyWorkHours: Decimal = 744

    public var monthlyNetIncome: Decimal
    public var averageMonthlyWorkHours: Decimal

    public init(
        monthlyNetIncome: Decimal = 0,
        averageMonthlyWorkHours: Decimal = 0
    ) {
        self.monthlyNetIncome = monthlyNetIncome
        self.averageMonthlyWorkHours = averageMonthlyWorkHours
    }

    public init(configuration: HoursOfLifeConfiguration) {
        monthlyNetIncome = configuration.monthlyNetIncome
        averageMonthlyWorkHours = configuration.averageMonthlyWorkHours
    }

    public func validationErrors() -> [HoursOfLifeConfigurationValidationError] {
        var errors: [HoursOfLifeConfigurationValidationError] = []
        if monthlyNetIncome <= 0 {
            errors.append(.incomeMustBePositive)
        }
        if averageMonthlyWorkHours <= 0 {
            errors.append(.workHoursMustBePositive)
        } else if averageMonthlyWorkHours > Self.maxMonthlyWorkHours {
            errors.append(.workHoursTooHigh)
        }
        return errors
    }

    public func validated() throws -> HoursOfLifeConfiguration {
        if let firstError = validationErrors().first {
            throw firstError
        }
        return HoursOfLifeConfiguration(
            monthlyNetIncome: monthlyNetIncome,
            averageMonthlyWorkHours: averageMonthlyWorkHours
        )
    }
}
