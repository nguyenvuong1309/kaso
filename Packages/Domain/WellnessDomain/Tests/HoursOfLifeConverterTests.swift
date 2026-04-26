import Foundation
import Testing
import TransactionDomain
@testable import WellnessDomain

@Test("converts transaction amount into work minutes and hours")
func convertsTransactionAmountIntoWorkMinutesAndHours() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 12_000_000,
        averageMonthlyWorkHours: 160
    )
    let transaction = Transaction(
        amount: 150_000,
        kind: .expense,
        category: .food,
        occurredAt: Date()
    )

    let conversion = try #require(
        HoursOfLifeConverter.convert(transaction: transaction, configuration: configuration)
    )

    #expect(conversion.amount == 150_000)
    #expect(conversion.workMinutes == 120)
    #expect(conversion.workHours == 2)
    #expect(conversion.roundedWorkMinutes == 120)
}

@Test("converts sub-hour amounts into minutes")
func convertsSubHourAmountsIntoMinutes() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 20_000_000,
        averageMonthlyWorkHours: 160
    )

    let conversion = try #require(
        HoursOfLifeConverter.convert(amount: 62_500, configuration: configuration)
    )

    #expect(conversion.workMinutes == 30)
    #expect(conversion.workHours == 0.5)
    #expect(conversion.wholeHours == 0)
    #expect(conversion.remainingMinutes == 30)
}

@Test("returns nil for zero or invalid configuration")
func returnsNilForZeroOrInvalidConfiguration() {
    #expect(
        HoursOfLifeConverter.convert(
            amount: 65_000,
            configuration: HoursOfLifeConfiguration(
                monthlyNetIncome: 0,
                averageMonthlyWorkHours: 160
            )
        ) == nil
    )
    #expect(
        HoursOfLifeConverter.convert(
            amount: 65_000,
            configuration: HoursOfLifeConfiguration(
                monthlyNetIncome: 20_000_000,
                averageMonthlyWorkHours: 0
            )
        ) == nil
    )
    #expect(
        HoursOfLifeConverter.convert(
            amount: 65_000,
            configuration: HoursOfLifeConfiguration(
                monthlyNetIncome: -1,
                averageMonthlyWorkHours: 160
            )
        ) == nil
    )
    #expect(
        HoursOfLifeConverter.convert(
            amount: 65_000,
            configuration: HoursOfLifeConfiguration(
                monthlyNetIncome: 20_000_000,
                averageMonthlyWorkHours: -1
            )
        ) == nil
    )
}

@Test("keeps zero amount as zero work time")
func keepsZeroAmountAsZeroWorkTime() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 12_000_000,
        averageMonthlyWorkHours: 160
    )

    let conversion = try #require(
        HoursOfLifeConverter.convert(amount: 0, configuration: configuration)
    )

    #expect(conversion.workMinutes == 0)
    #expect(conversion.workHours == 0)
    #expect(conversion.roundedWorkMinutes == 0)
    #expect(conversion.wholeHours == 0)
    #expect(conversion.remainingMinutes == 0)
}

@Test("exposes formatting-friendly hour and minute values")
func exposesFormattingFriendlyHourAndMinuteValues() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 12_000_000,
        averageMonthlyWorkHours: 160
    )

    let conversion = try #require(
        HoursOfLifeConverter.convert(amount: 212_500, configuration: configuration)
    )

    #expect(conversion.workMinutes == 170)
    #expect(conversion.roundedWorkMinutes == 170)
    #expect(conversion.wholeHours == 2)
    #expect(conversion.remainingMinutes == 50)
}
