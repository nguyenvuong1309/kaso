import Foundation
import Testing
@testable import WellnessDomain

@Test("draft accepts positive income and reasonable work hours")
func draftAcceptsPositiveIncomeAndReasonableWorkHours() throws {
    let draft = HoursOfLifeConfigurationDraft(
        monthlyNetIncome: 20_000_000,
        averageMonthlyWorkHours: 160
    )

    #expect(draft.validationErrors().isEmpty)

    let configuration = try draft.validated()
    #expect(configuration.monthlyNetIncome == 20_000_000)
    #expect(configuration.averageMonthlyWorkHours == 160)
}

@Test("draft rejects non-positive income")
func draftRejectsNonPositiveIncome() {
    #expect(
        HoursOfLifeConfigurationDraft(
            monthlyNetIncome: 0,
            averageMonthlyWorkHours: 160
        ).validationErrors() == [.incomeMustBePositive]
    )
    #expect(
        HoursOfLifeConfigurationDraft(
            monthlyNetIncome: -1,
            averageMonthlyWorkHours: 160
        ).validationErrors() == [.incomeMustBePositive]
    )
}

@Test("draft rejects non-positive work hours")
func draftRejectsNonPositiveWorkHours() {
    #expect(
        HoursOfLifeConfigurationDraft(
            monthlyNetIncome: 20_000_000,
            averageMonthlyWorkHours: 0
        ).validationErrors() == [.workHoursMustBePositive]
    )
    #expect(
        HoursOfLifeConfigurationDraft(
            monthlyNetIncome: 20_000_000,
            averageMonthlyWorkHours: -1
        ).validationErrors() == [.workHoursMustBePositive]
    )
}

@Test("draft rejects unrealistic work hours")
func draftRejectsUnrealisticWorkHours() {
    #expect(
        HoursOfLifeConfigurationDraft(
            monthlyNetIncome: 20_000_000,
            averageMonthlyWorkHours: 800
        ).validationErrors() == [.workHoursTooHigh]
    )
}

@Test("draft surfaces all errors when both fields invalid")
func draftSurfacesAllErrorsWhenBothFieldsInvalid() {
    let draft = HoursOfLifeConfigurationDraft(
        monthlyNetIncome: 0,
        averageMonthlyWorkHours: 0
    )

    #expect(
        Set(draft.validationErrors()) == Set([
            .incomeMustBePositive,
            .workHoursMustBePositive,
        ])
    )
}

@Test("draft from configuration round-trips fields")
func draftFromConfigurationRoundTripsFields() throws {
    let configuration = HoursOfLifeConfiguration(
        monthlyNetIncome: 18_500_000,
        averageMonthlyWorkHours: 168
    )
    let draft = HoursOfLifeConfigurationDraft(configuration: configuration)

    #expect(draft.monthlyNetIncome == configuration.monthlyNetIncome)
    #expect(draft.averageMonthlyWorkHours == configuration.averageMonthlyWorkHours)
    #expect(try draft.validated() == configuration)
}
