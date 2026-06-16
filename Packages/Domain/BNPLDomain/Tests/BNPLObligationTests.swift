import Foundation
import Testing
@testable import BNPLDomain

// MARK: - Helpers

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
) throws -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    return try #require(calendar.date(from: components))
}

private func gregorian() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .gmt
    return calendar
}

// MARK: - BNPLProvider

@Test("BNPLProvider exposes id equal to rawValue for every case")
func providerIdMatchesRawValue() {
    for provider in BNPLProvider.allCases {
        #expect(provider.id == provider.rawValue)
    }
}

@Test("BNPLProvider has correct display names")
func providerDisplayNames() {
    #expect(BNPLProvider.fundiin.displayName == "Fundiin")
    #expect(BNPLProvider.kredivo.displayName == "Kredivo")
    #expect(BNPLProvider.atome.displayName == "Atome")
    #expect(BNPLProvider.shopeePayLater.displayName == "Shopee PayLater")
    #expect(BNPLProvider.momoPostPay.displayName == "MoMo Postpaid")
    #expect(BNPLProvider.homeCredit.displayName == "Home Credit")
    #expect(BNPLProvider.generic.displayName == "Khác")
}

@Test("BNPLProvider maps to SF Symbol names")
func providerSymbolNames() {
    #expect(BNPLProvider.fundiin.symbolName == "creditcard.fill")
    #expect(BNPLProvider.kredivo.symbolName == "creditcard.fill")
    #expect(BNPLProvider.atome.symbolName == "creditcard.fill")
    #expect(BNPLProvider.shopeePayLater.symbolName == "bag.fill")
    #expect(BNPLProvider.momoPostPay.symbolName == "wallet.pass.fill")
    #expect(BNPLProvider.homeCredit.symbolName == "house.circle.fill")
    #expect(BNPLProvider.generic.symbolName == "dollarsign.circle.fill")
}

@Test("BNPLProvider enumerates all seven cases")
func providerAllCasesCount() {
    #expect(BNPLProvider.allCases.count == 7)
}

@Test("BNPLProvider round-trips through Codable")
func providerCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for provider in BNPLProvider.allCases {
        let data = try encoder.encode(provider)
        let decoded = try decoder.decode(BNPLProvider.self, from: data)
        #expect(decoded == provider)
    }
}

// MARK: - BNPLStatus

@Test("BNPLStatus round-trips through Codable")
func statusCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for status in [BNPLStatus.active, .completed, .overdue] {
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(BNPLStatus.self, from: data)
        #expect(decoded == status)
    }
}

// MARK: - BNPLInstallment

@Test("BNPLInstallment defaults isPaid to false and generates an id")
func installmentDefaults() throws {
    let calendar = gregorian()
    let due = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let installment = BNPLInstallment(dueDate: due, amount: 1_000_000)
    #expect(installment.isPaid == false)
    #expect(installment.amount == 1_000_000)
    #expect(installment.dueDate == due)
}

@Test("BNPLInstallment round-trips through Codable preserving fields")
func installmentCodableRoundTrip() throws {
    let calendar = gregorian()
    let due = try makeDate(year: 2026, month: 8, day: 15, calendar: calendar)
    let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")
    let installment = BNPLInstallment(
        id: try #require(id),
        dueDate: due,
        amount: 2_500_000,
        isPaid: true
    )
    let data = try JSONEncoder().encode(installment)
    let decoded = try JSONDecoder().decode(BNPLInstallment.self, from: data)
    #expect(decoded == installment)
}

// MARK: - BNPLObligation amounts

@Test("remainingAmount and paidAmount are zero for empty installments")
func obligationEmptyAmounts() throws {
    let calendar = gregorian()
    let date = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .generic,
        purchaseName: "Empty",
        totalAmount: 0,
        purchaseDate: date,
        installmentCount: 0,
        installments: []
    )
    #expect(obligation.remainingAmount == 0)
    #expect(obligation.paidAmount == 0)
}

@Test("remainingAmount sums only unpaid installments")
func obligationRemainingAmount() throws {
    let calendar = gregorian()
    let d1 = try makeDate(year: 2026, month: 1, day: 5, calendar: calendar)
    let d2 = try makeDate(year: 2026, month: 2, day: 5, calendar: calendar)
    let d3 = try makeDate(year: 2026, month: 3, day: 5, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .atome,
        purchaseName: "Mixed",
        totalAmount: 3_000_000,
        purchaseDate: d1,
        installmentCount: 3,
        installments: [
            BNPLInstallment(dueDate: d1, amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: d2, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: d3, amount: 1_000_000, isPaid: false),
        ]
    )
    #expect(obligation.remainingAmount == 2_000_000)
    #expect(obligation.paidAmount == 1_000_000)
}

@Test("paidAmount equals total when fully paid and remaining is zero")
func obligationFullyPaidAmounts() throws {
    let calendar = gregorian()
    let d1 = try makeDate(year: 2026, month: 1, day: 5, calendar: calendar)
    let d2 = try makeDate(year: 2026, month: 2, day: 5, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .kredivo,
        purchaseName: "Paid",
        totalAmount: 2_000_000,
        purchaseDate: d1,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: d1, amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: d2, amount: 1_000_000, isPaid: true),
        ]
    )
    #expect(obligation.paidAmount == 2_000_000)
    #expect(obligation.remainingAmount == 0)
}

// MARK: - BNPLObligation.status

@Test("status returns completed when there are no installments")
func statusCompletedWhenEmpty() throws {
    let calendar = gregorian()
    let date = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .generic,
        purchaseName: "Empty",
        totalAmount: 0,
        purchaseDate: date,
        installmentCount: 0,
        installments: []
    )
    #expect(obligation.status(at: date) == .completed)
}

@Test("status returns active when all unpaid installments are in the future")
func statusActiveWhenFutureUnpaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let future1 = try makeDate(year: 2026, month: 7, day: 16, calendar: calendar)
    let future2 = try makeDate(year: 2026, month: 8, day: 16, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .fundiin,
        purchaseName: "Active",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: future1, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: future2, amount: 1_000_000, isPaid: false),
        ]
    )
    #expect(obligation.status(at: reference) == .active)
}

@Test("status returns overdue when a past installment remains unpaid")
func statusOverdueWhenPastUnpaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let past = try makeDate(year: 2026, month: 5, day: 16, calendar: calendar)
    let future = try makeDate(year: 2026, month: 7, day: 16, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .homeCredit,
        purchaseName: "Overdue",
        totalAmount: 2_000_000,
        purchaseDate: past,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: past, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: future, amount: 1_000_000, isPaid: false),
        ]
    )
    #expect(obligation.status(at: reference) == .overdue)
}

@Test("status ignores paid past installments and stays active")
func statusActiveWhenPastIsPaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let past = try makeDate(year: 2026, month: 5, day: 16, calendar: calendar)
    let future = try makeDate(year: 2026, month: 7, day: 16, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .momoPostPay,
        purchaseName: "PaidPast",
        totalAmount: 2_000_000,
        purchaseDate: past,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: past, amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: future, amount: 1_000_000, isPaid: false),
        ]
    )
    #expect(obligation.status(at: reference) == .active)
}

// MARK: - BNPLObligation.nextInstallment

@Test("nextInstallment returns earliest unpaid installment by due date")
func nextInstallmentReturnsEarliestUnpaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let early = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let late = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .atome,
        purchaseName: "Next",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: late, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: early, amount: 1_500_000, isPaid: false),
        ]
    )
    let next = try #require(obligation.nextInstallment(after: reference))
    #expect(next.dueDate == early)
    #expect(next.amount == 1_500_000)
}

@Test("nextInstallment skips paid installments")
func nextInstallmentSkipsPaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let early = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let late = try makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .atome,
        purchaseName: "NextSkip",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: early, amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: late, amount: 1_000_000, isPaid: false),
        ]
    )
    let next = try #require(obligation.nextInstallment(after: reference))
    #expect(next.dueDate == late)
}

@Test("nextInstallment returns nil when all installments are paid")
func nextInstallmentNilWhenAllPaid() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let d1 = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .atome,
        purchaseName: "AllPaid",
        totalAmount: 1_000_000,
        purchaseDate: reference,
        installmentCount: 1,
        installments: [
            BNPLInstallment(dueDate: d1, amount: 1_000_000, isPaid: true),
        ]
    )
    #expect(obligation.nextInstallment(after: reference) == nil)
}

// MARK: - BNPLObligation Codable

@Test("BNPLObligation round-trips through Codable including optional note")
func obligationCodableRoundTrip() throws {
    let calendar = gregorian()
    let purchase = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let due = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        id: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222")),
        provider: .shopeePayLater,
        purchaseName: "Laptop",
        totalAmount: 12_000_000,
        purchaseDate: purchase,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: due, amount: 12_000_000)],
        note: "Black Friday"
    )
    let data = try JSONEncoder().encode(obligation)
    let decoded = try JSONDecoder().decode(BNPLObligation.self, from: data)
    #expect(decoded == obligation)
    #expect(decoded.note == "Black Friday")
}

// MARK: - BNPLInstallmentBuilder

@Test("generateMonthly returns empty array for zero installment count")
func builderZeroCount() throws {
    let calendar = gregorian()
    let start = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let result = BNPLInstallmentBuilder.generateMonthly(
        totalAmount: 3_000_000,
        installmentCount: 0,
        startDate: start,
        calendar: calendar
    )
    #expect(result.isEmpty)
}

@Test("generateMonthly returns empty array for negative installment count")
func builderNegativeCount() throws {
    let calendar = gregorian()
    let start = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let result = BNPLInstallmentBuilder.generateMonthly(
        totalAmount: 3_000_000,
        installmentCount: -2,
        startDate: start,
        calendar: calendar
    )
    #expect(result.isEmpty)
}

@Test("generateMonthly splits amount evenly and spaces due dates one month apart")
func builderEvenSplitAndDates() throws {
    let calendar = gregorian()
    let start = try makeDate(year: 2026, month: 1, day: 10, calendar: calendar)
    let result = BNPLInstallmentBuilder.generateMonthly(
        totalAmount: 4_000_000,
        installmentCount: 4,
        startDate: start,
        calendar: calendar
    )
    #expect(result.count == 4)
    #expect(result.allSatisfy { $0.amount == 1_000_000 })
    #expect(result.allSatisfy { $0.isPaid == false })
    #expect(result[0].dueDate == start)
    let m1 = try makeDate(year: 2026, month: 2, day: 10, calendar: calendar)
    let m2 = try makeDate(year: 2026, month: 3, day: 10, calendar: calendar)
    let m3 = try makeDate(year: 2026, month: 4, day: 10, calendar: calendar)
    #expect(result[1].dueDate == m1)
    #expect(result[2].dueDate == m2)
    #expect(result[3].dueDate == m3)
}

@Test("generateMonthly with single installment uses full total amount")
func builderSingleInstallment() throws {
    let calendar = gregorian()
    let start = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let result = BNPLInstallmentBuilder.generateMonthly(
        totalAmount: 5_000_000,
        installmentCount: 1,
        startDate: start,
        calendar: calendar
    )
    #expect(result.count == 1)
    #expect(result[0].amount == 5_000_000)
    #expect(result[0].dueDate == start)
}

@Test("generateMonthly sum equals total for evenly divisible amounts")
func builderSumEqualsTotal() throws {
    let calendar = gregorian()
    let start = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let result = BNPLInstallmentBuilder.generateMonthly(
        totalAmount: 6_000_000,
        installmentCount: 3,
        startDate: start,
        calendar: calendar
    )
    let sum = result.reduce(Decimal(0)) { $0 + $1.amount }
    #expect(sum == 6_000_000)
}
