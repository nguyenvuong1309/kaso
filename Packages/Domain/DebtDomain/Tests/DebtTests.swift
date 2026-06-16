import Foundation
import Testing
@testable import DebtDomain
@testable import WealthDomain

@Suite("Debt")
struct DebtTests {
    @Test("monthlyInterestRate divides annual percent by 100 and 12")
    func monthlyInterestRate() {
        let debt = makeDebt(annualInterestRatePercent: 12)
        #expect(debt.monthlyInterestRate == Decimal(12) / Decimal(100) / Decimal(12))
        #expect(debt.monthlyInterestRate == Decimal(string: "0.01"))
    }

    @Test("monthlyInterestRate is zero for zero annual rate")
    func monthlyInterestRateZero() {
        let debt = makeDebt(annualInterestRatePercent: 0)
        #expect(debt.monthlyInterestRate == 0)
    }

    @Test("toLiability maps remaining balance as of date")
    func toLiabilityRemaining() throws {
        let debt = makeDebt(
            principal: 100_000_000,
            annualInterestRatePercent: 0,
            termMonths: 10
        )
        let asOf = try makeDate(year: 2026, month: 6, day: 15)
        let liability = debt.toLiability(asOf: asOf, calendar: makeCalendar())
        #expect(liability.id == debt.id)
        #expect(liability.name == debt.name)
        #expect(liability.note == debt.note)
        #expect(liability.isAutoTracked)
        #expect(liability.lastUpdatedAt == asOf)
        #expect(liability.principalRemaining < debt.principal)
    }

    @Test("toLiability falls back to full principal for invalid debt")
    func toLiabilityInvalidFallsBack() throws {
        let debt = Debt(
            name: "Invalid",
            type: .other,
            principal: 50_000_000,
            annualInterestRatePercent: 5,
            termMonths: 0,
            startDate: try makeDate(year: 2026, month: 1, day: 1)
        )
        let asOf = try makeDate(year: 2026, month: 6, day: 1)
        let liability = debt.toLiability(asOf: asOf, calendar: makeCalendar())
        #expect(liability.principalRemaining == 50_000_000)
    }

    @Test("DebtType maps to matching LiabilityType for every case")
    func debtTypeToLiabilityTypeMapping() {
        let pairs: [(DebtType, LiabilityType)] = [
            (.mortgage, .mortgage),
            (.autoLoan, .autoLoan),
            (.personalLoan, .personalLoan),
            (.creditCard, .creditCard),
            (.studentLoan, .studentLoan),
            (.bnpl, .bnpl),
            (.other, .other),
        ]
        for (debtType, liabilityType) in pairs {
            #expect(debtType.toLiabilityType() == liabilityType)
        }
    }

    @Test("debt round-trips through Codable")
    func codableRoundTrip() throws {
        let debt = makeDebt()
        let data = try JSONEncoder().encode(debt)
        let decoded = try JSONDecoder().decode(Debt.self, from: data)
        #expect(decoded == debt)
    }

    private func makeDebt(
        principal: Decimal = 120_000_000,
        annualInterestRatePercent: Decimal = 12,
        termMonths: Int = 12
    ) -> Debt {
        Debt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            name: "Vay",
            type: .personalLoan,
            principal: principal,
            annualInterestRatePercent: annualInterestRatePercent,
            termMonths: termMonths,
            startDate: fixedStart(),
            paymentDay: 1,
            monthlyPaymentOverride: nil,
            note: "ghi chú",
            createdAt: fixedStart()
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
