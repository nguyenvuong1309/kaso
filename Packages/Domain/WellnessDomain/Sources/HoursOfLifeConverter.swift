import Foundation
import TransactionDomain

public struct HoursOfLifeConfiguration: Codable, Equatable, Sendable {
    public let monthlyNetIncome: Decimal
    public let averageMonthlyWorkHours: Decimal

    public var isValid: Bool {
        monthlyNetIncome > .zero && averageMonthlyWorkHours > .zero
    }

    public var netIncomePerWorkHour: Decimal? {
        guard isValid else {
            return nil
        }

        return monthlyNetIncome / averageMonthlyWorkHours
    }

    public init(
        monthlyNetIncome: Decimal,
        averageMonthlyWorkHours: Decimal
    ) {
        self.monthlyNetIncome = monthlyNetIncome
        self.averageMonthlyWorkHours = averageMonthlyWorkHours
    }
}

public struct HoursOfLifeConversion: Codable, Equatable, Sendable {
    public let amount: Decimal
    public let workMinutes: Decimal
    public let workHours: Decimal
    public let roundedWorkMinutes: Int

    public var wholeHours: Int {
        roundedWorkMinutes / 60
    }

    public var remainingMinutes: Int {
        roundedWorkMinutes % 60
    }

    public init(
        amount: Decimal,
        workMinutes: Decimal,
        workHours: Decimal,
        roundedWorkMinutes: Int
    ) {
        self.amount = amount
        self.workMinutes = workMinutes
        self.workHours = workHours
        self.roundedWorkMinutes = roundedWorkMinutes
    }
}

public enum HoursOfLifeConverter: Sendable {
    public static func convert(
        transaction: Transaction,
        configuration: HoursOfLifeConfiguration
    ) -> HoursOfLifeConversion? {
        convert(amount: transaction.amount, configuration: configuration)
    }

    public static func convert(
        amount: Decimal,
        configuration: HoursOfLifeConfiguration
    ) -> HoursOfLifeConversion? {
        guard configuration.isValid else {
            return nil
        }

        let normalizedAmount = amount < .zero ? -amount : amount
        let workMinutes = normalizedAmount
            * configuration.averageMonthlyWorkHours
            * 60
            / configuration.monthlyNetIncome
        let workHours = workMinutes / 60

        return HoursOfLifeConversion(
            amount: normalizedAmount,
            workMinutes: workMinutes,
            workHours: workHours,
            roundedWorkMinutes: roundedWholeMinutes(from: workMinutes)
        )
    }
}

private extension HoursOfLifeConverter {
    static func roundedWholeMinutes(from minutes: Decimal) -> Int {
        let normalizedMinutes = minutes < .zero ? Decimal.zero : minutes
        var source = normalizedMinutes
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 0, .plain)

        return NSDecimalNumber(decimal: rounded).intValue
    }
}
