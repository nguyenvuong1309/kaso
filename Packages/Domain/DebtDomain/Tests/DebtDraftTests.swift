import Foundation
import Testing
@testable import DebtDomain

@Suite("DebtDraft")
struct DebtDraftTests {
    @Test("default init produces no validation errors only after fixing principal")
    func defaultDraftRequiresNameAndPrincipal() {
        let draft = DebtDraft()
        let errors = draft.validationErrors()
        #expect(errors.contains(.nameRequired))
        #expect(errors.contains(.principalMustBePositive))
        #expect(!errors.contains(.termMonthsMustBePositive))
        #expect(!errors.contains(.paymentDayOutOfRange))
    }

    @Test("valid draft reports no errors")
    func validDraftNoErrors() throws {
        let draft = makeValidDraft()
        #expect(draft.validationErrors().isEmpty)
    }

    @Test("paymentDay boundaries 1 and 31 are valid; 0 and 32 are not")
    func paymentDayBoundaries() throws {
        var draft = makeValidDraft()
        draft.paymentDay = 1
        #expect(!draft.validationErrors().contains(.paymentDayOutOfRange))
        draft.paymentDay = 31
        #expect(!draft.validationErrors().contains(.paymentDayOutOfRange))
        draft.paymentDay = 0
        #expect(draft.validationErrors().contains(.paymentDayOutOfRange))
        draft.paymentDay = 32
        #expect(draft.validationErrors().contains(.paymentDayOutOfRange))
    }

    @Test("termMonths boundary at max is valid, max+1 is too long")
    func termMonthsBoundary() throws {
        var draft = makeValidDraft()
        draft.termMonths = DebtDraft.maxTermMonths
        #expect(draft.validationErrors().isEmpty)
        draft.termMonths = DebtDraft.maxTermMonths + 1
        #expect(draft.validationErrors() == [.termMonthsTooLong])
    }

    @Test("zero interest rate is valid, negative is not")
    func interestRateValidation() throws {
        var draft = makeValidDraft()
        draft.annualInterestRatePercent = 0
        #expect(draft.validationErrors().isEmpty)
        draft.annualInterestRatePercent = -0.01
        #expect(draft.validationErrors().contains(.annualInterestRateCannotBeNegative))
    }

    @Test("validated trims name and empties whitespace note")
    func validatedTrimsFields() throws {
        var draft = makeValidDraft()
        draft.name = "  Vay nhà  "
        draft.note = "   "
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
        let createdAt = try makeDate(year: 2026, month: 3, day: 1)
        let debt = try draft.validated(id: id, createdAt: createdAt)
        #expect(debt.id == id)
        #expect(debt.name == "Vay nhà")
        #expect(debt.note == nil)
        #expect(debt.createdAt == createdAt)
    }

    @Test("validated preserves non-empty trimmed note")
    func validatedKeepsNote() throws {
        var draft = makeValidDraft()
        draft.note = "  hello  "
        let debt = try draft.validated()
        #expect(debt.note == "hello")
    }

    @Test("validated throws first validation error")
    func validatedThrowsFirstError() throws {
        var draft = makeValidDraft()
        draft.name = ""
        draft.principal = 0
        #expect(throws: DebtValidationError.nameRequired) {
            _ = try draft.validated()
        }
    }

    @Test("updating preserves existing id and createdAt")
    func updatingPreservesIdentity() throws {
        let existing = Debt(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            name: "Old",
            type: .creditCard,
            principal: 5_000_000,
            annualInterestRatePercent: 24,
            termMonths: 6,
            startDate: try makeDate(year: 2025, month: 1, day: 1),
            createdAt: try makeDate(year: 2025, month: 1, day: 1)
        )
        var draft = makeValidDraft()
        draft.name = "New name"
        draft.principal = 9_000_000
        let updated = try draft.updating(existing: existing)
        #expect(updated.id == existing.id)
        #expect(updated.createdAt == existing.createdAt)
        #expect(updated.name == "New name")
        #expect(updated.principal == 9_000_000)
    }

    @Test("updating throws when draft invalid")
    func updatingThrowsWhenInvalid() throws {
        let existing = Debt(
            name: "Old",
            type: .other,
            principal: 1_000,
            annualInterestRatePercent: 1,
            termMonths: 6,
            startDate: try makeDate(year: 2025, month: 1, day: 1)
        )
        var draft = makeValidDraft()
        draft.termMonths = 0
        #expect(throws: DebtValidationError.termMonthsMustBePositive) {
            _ = try draft.updating(existing: existing)
        }
    }

    @Test("init(debt:) copies every editable field")
    func initFromDebt() throws {
        let debt = Debt(
            name: "Source",
            type: .autoLoan,
            principal: 300_000_000,
            annualInterestRatePercent: 7,
            termMonths: 48,
            startDate: try makeDate(year: 2026, month: 2, day: 5),
            paymentDay: 5,
            monthlyPaymentOverride: 7_500_000,
            note: "xe"
        )
        let draft = DebtDraft(debt: debt)
        #expect(draft.name == debt.name)
        #expect(draft.type == debt.type)
        #expect(draft.principal == debt.principal)
        #expect(draft.annualInterestRatePercent == debt.annualInterestRatePercent)
        #expect(draft.termMonths == debt.termMonths)
        #expect(draft.startDate == debt.startDate)
        #expect(draft.paymentDay == debt.paymentDay)
        #expect(draft.monthlyPaymentOverride == debt.monthlyPaymentOverride)
        #expect(draft.note == debt.note)
    }

    @Test("draft round-trips through Codable")
    func codableRoundTrip() throws {
        let draft = makeValidDraft()
        let data = try JSONEncoder().encode(draft)
        let decoded = try JSONDecoder().decode(DebtDraft.self, from: data)
        #expect(decoded == draft)
    }

    @Test("validation error raw values are stable")
    func validationErrorRawValues() {
        #expect(DebtValidationError.nameRequired.rawValue == "nameRequired")
        #expect(DebtValidationError.principalMustBePositive.rawValue == "principalMustBePositive")
        #expect(DebtValidationError.termMonthsTooLong.rawValue == "termMonthsTooLong")
    }

    private func makeValidDraft() -> DebtDraft {
        DebtDraft(
            name: "Vay hợp lệ",
            type: .personalLoan,
            principal: 50_000_000,
            annualInterestRatePercent: 8,
            termMonths: 24,
            startDate: fixedStart(),
            paymentDay: 15,
            monthlyPaymentOverride: nil,
            note: nil
        )
    }

    private func fixedStart() -> Date {
        DateComponents(calendar: makeCalendar(), year: 2026, month: 1, day: 1).date ?? Date(timeIntervalSince1970: 0)
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        try #require(
            DateComponents(
                calendar: makeCalendar(),
                year: year,
                month: month,
                day: day
            ).date
        )
    }
}
