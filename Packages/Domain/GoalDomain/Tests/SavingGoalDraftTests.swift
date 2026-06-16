import Foundation
import Testing
@testable import GoalDomain

@Test("returns no errors for a fully valid draft")
func draftNoErrorsWhenValid() throws {
    let calendar = draftFixedCalendar()
    let draft = SavingGoalDraft(
        name: "Valid goal",
        targetAmount: 10_000_000,
        currentAmount: 1_000_000,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    #expect(draft.validationErrors(asOf: try draftDate(year: 2026, month: 4, day: 1), calendar: calendar).isEmpty)
}

@Test("flags name required when name is only whitespace")
func draftNameRequiredWhitespace() throws {
    let calendar = draftFixedCalendar()
    let draft = SavingGoalDraft(
        name: "\n\t  ",
        targetAmount: 10_000_000,
        currentAmount: 0,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    #expect(
        draft.validationErrors(asOf: try draftDate(year: 2026, month: 4, day: 1), calendar: calendar) == [.nameRequired]
    )
}

@Test("flags negative target as not positive")
func draftNegativeTarget() throws {
    let calendar = draftFixedCalendar()
    let draft = SavingGoalDraft(
        name: "Negative",
        targetAmount: -5,
        currentAmount: 0,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    #expect(
        draft.validationErrors(asOf: try draftDate(year: 2026, month: 4, day: 1), calendar: calendar)
            == [.targetAmountMustBePositive]
    )
}

@Test("does not flag exceed-target when target is zero")
func draftNoExceedErrorWhenTargetZero() throws {
    let calendar = draftFixedCalendar()
    let draft = SavingGoalDraft(
        name: "Zero target",
        targetAmount: 0,
        currentAmount: 1_000,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    let errors = draft.validationErrors(asOf: try draftDate(year: 2026, month: 4, day: 1), calendar: calendar)
    #expect(errors == [.targetAmountMustBePositive])
    #expect(errors.contains(.currentAmountCannotExceedTargetAmount) == false)
}

@Test("allows current amount equal to target")
func draftCurrentEqualsTargetAllowed() throws {
    let calendar = draftFixedCalendar()
    let draft = SavingGoalDraft(
        name: "Equal",
        targetAmount: 10_000_000,
        currentAmount: 10_000_000,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    #expect(draft.validationErrors(asOf: try draftDate(year: 2026, month: 4, day: 1), calendar: calendar).isEmpty)
}

@Test("flags deadline equal to current day as not in future")
func draftDeadlineSameDayNotFuture() throws {
    let calendar = draftFixedCalendar()
    let today = try draftDate(year: 2026, month: 4, day: 1)
    let draft = SavingGoalDraft(
        name: "Today deadline",
        targetAmount: 10_000_000,
        currentAmount: 0,
        deadline: today
    )

    #expect(draft.validationErrors(asOf: today, calendar: calendar) == [.deadlineMustBeInFuture])
}

@Test("validated uses default current amount and nil image identifier")
func draftValidatedDefaults() throws {
    let calendar = draftFixedCalendar()
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000BB"))
    let createdAt = try draftDate(year: 2026, month: 4, day: 1)
    let draft = SavingGoalDraft(
        name: "Defaulted",
        targetAmount: 5_000_000,
        deadline: try draftDate(year: 2026, month: 12, day: 31)
    )

    let goal = try draft.validated(id: id, createdAt: createdAt, calendar: calendar)

    #expect(goal.currentAmount == 0)
    #expect(goal.imageIdentifier == nil)
    #expect(goal.deadline == draft.deadline)
}

@Test("validated throws the first error in declaration order")
func draftValidatedThrowsFirstError() throws {
    let calendar = draftFixedCalendar()
    let createdAt = try draftDate(year: 2026, month: 4, day: 1)
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-0000000000CC"))
    // Valid name, invalid target -> first error should be targetAmountMustBePositive.
    let draft = SavingGoalDraft(
        name: "Has name",
        targetAmount: 0,
        currentAmount: -1,
        deadline: try draftDate(year: 2026, month: 3, day: 1)
    )

    do {
        _ = try draft.validated(id: id, createdAt: createdAt, calendar: calendar)
        Issue.record("Expected validation to throw")
    } catch let error as SavingGoalValidationError {
        #expect(error == .targetAmountMustBePositive)
    }
}

@Test("round-trips draft through Codable")
func draftCodableRoundTrip() throws {
    let draft = SavingGoalDraft(
        name: "Codable",
        targetAmount: 3_000_000,
        currentAmount: 500_000,
        deadline: try draftDate(year: 2027, month: 6, day: 30),
        imageIdentifier: "draft-img"
    )

    let data = try JSONEncoder().encode(draft)
    let decoded = try JSONDecoder().decode(SavingGoalDraft.self, from: data)

    #expect(decoded == draft)
}

@Test("validation error encodes as its raw string value")
func validationErrorRawValue() throws {
    #expect(SavingGoalValidationError.nameRequired.rawValue == "nameRequired")
    #expect(SavingGoalValidationError.targetAmountMustBePositive.rawValue == "targetAmountMustBePositive")
    #expect(SavingGoalValidationError.currentAmountCannotBeNegative.rawValue == "currentAmountCannotBeNegative")
    #expect(
        SavingGoalValidationError.currentAmountCannotExceedTargetAmount.rawValue
            == "currentAmountCannotExceedTargetAmount"
    )
    #expect(SavingGoalValidationError.deadlineMustBeInFuture.rawValue == "deadlineMustBeInFuture")
}

private func draftFixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func draftDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: draftFixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
