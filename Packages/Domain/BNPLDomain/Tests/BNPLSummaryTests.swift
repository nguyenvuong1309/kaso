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

// MARK: - BNPLHealth

@Test("BNPLHealth treats zero income as critical")
func healthZeroIncomeCritical() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 0, monthlyIncome: 0) == .critical)
    #expect(BNPLHealth.evaluate(monthlyObligation: 100, monthlyIncome: 0) == .critical)
}

@Test("BNPLHealth treats negative income as critical")
func healthNegativeIncomeCritical() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 1_000_000, monthlyIncome: -5_000_000) == .critical)
}

@Test("BNPLHealth is safe below 10 percent")
func healthSafeBelowTenPercent() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 0, monthlyIncome: 10_000_000) == .safe)
    #expect(BNPLHealth.evaluate(monthlyObligation: 999_999, monthlyIncome: 10_000_000) == .safe)
}

@Test("BNPLHealth boundary at exactly 10 percent is caution")
func healthBoundaryTenPercent() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 1_000_000, monthlyIncome: 10_000_000) == .caution)
}

@Test("BNPLHealth boundary at exactly 20 percent is overexposed")
func healthBoundaryTwentyPercent() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 2_000_000, monthlyIncome: 10_000_000) == .overexposed)
}

@Test("BNPLHealth boundary at exactly 30 percent is critical")
func healthBoundaryThirtyPercent() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 3_000_000, monthlyIncome: 10_000_000) == .critical)
}

@Test("BNPLHealth caution range is 10 to 20 percent")
func healthCautionRange() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 1_500_000, monthlyIncome: 10_000_000) == .caution)
    #expect(BNPLHealth.evaluate(monthlyObligation: 1_999_999, monthlyIncome: 10_000_000) == .caution)
}

@Test("BNPLHealth overexposed range is 20 to 30 percent")
func healthOverexposedRange() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 2_500_000, monthlyIncome: 10_000_000) == .overexposed)
    #expect(BNPLHealth.evaluate(monthlyObligation: 2_999_999, monthlyIncome: 10_000_000) == .overexposed)
}

@Test("BNPLHealth above 30 percent is critical")
func healthAboveThirtyCritical() {
    #expect(BNPLHealth.evaluate(monthlyObligation: 5_000_000, monthlyIncome: 10_000_000) == .critical)
}

@Test("BNPLHealth nameKey is namespaced by rawValue")
func healthNameKey() {
    #expect(BNPLHealth.safe.nameKey == "bnpl.health.safe")
    #expect(BNPLHealth.caution.nameKey == "bnpl.health.caution")
    #expect(BNPLHealth.overexposed.nameKey == "bnpl.health.overexposed")
    #expect(BNPLHealth.critical.nameKey == "bnpl.health.critical")
}

@Test("BNPLHealth round-trips through Codable")
func healthCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for health in [BNPLHealth.safe, .caution, .overexposed, .critical] {
        let data = try encoder.encode(health)
        let decoded = try decoder.decode(BNPLHealth.self, from: data)
        #expect(decoded == health)
    }
}

// MARK: - BNPLMonthlyExposure

@Test("BNPLMonthlyExposure builds zero-padded id from year and month")
func monthlyExposureId() {
    let exposure = BNPLMonthlyExposure(year: 2026, month: 3, totalDue: 1_000_000, installmentCount: 2)
    #expect(exposure.id == "2026-03")
    #expect(exposure.year == 2026)
    #expect(exposure.month == 3)
    #expect(exposure.totalDue == 1_000_000)
    #expect(exposure.installmentCount == 2)
}

@Test("BNPLMonthlyExposure pads double-digit month without truncation")
func monthlyExposureIdDoubleDigitMonth() {
    let exposure = BNPLMonthlyExposure(year: 2026, month: 12, totalDue: 0, installmentCount: 0)
    #expect(exposure.id == "2026-12")
}

// MARK: - BNPLSummaryBuilder empty / completed

@Test("build returns zeroed safe summary for empty obligations")
func buildEmptyObligations() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let summary = BNPLSummaryBuilder.build(
        obligations: [],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.totalActiveObligations == 0)
    #expect(summary.totalOutstanding == 0)
    #expect(summary.currentMonthDue == 0)
    #expect(summary.nextThreeMonthsDue == 0)
    #expect(summary.overdueAmount == 0)
    #expect(summary.exposureRatio == 0)
    #expect(summary.nextInstallmentDate == nil)
    #expect(summary.health == .safe)
    #expect(summary.monthlyExposures.count == 6)
}

@Test("build excludes fully completed obligations from active count")
func buildExcludesCompleted() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let due = try makeDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let completed = BNPLObligation(
        provider: .atome,
        purchaseName: "Done",
        totalAmount: 1_000_000,
        purchaseDate: due,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: due, amount: 1_000_000, isPaid: true)]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [completed],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.totalActiveObligations == 0)
    #expect(summary.totalOutstanding == 0)
}

// MARK: - BNPLSummaryBuilder aggregation

@Test("build aggregates current month, three-month window, and outstanding")
func buildAggregatesWindows() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jun = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
    let jul = try makeDate(year: 2026, month: 7, day: 20, calendar: calendar)
    let aug = try makeDate(year: 2026, month: 8, day: 20, calendar: calendar)
    let oct = try makeDate(year: 2026, month: 10, day: 20, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .shopeePayLater,
        purchaseName: "Spread",
        totalAmount: 4_000_000,
        purchaseDate: reference,
        installmentCount: 4,
        installments: [
            BNPLInstallment(dueDate: jun, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: jul, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: aug, amount: 1_000_000, isPaid: false),
            BNPLInstallment(dueDate: oct, amount: 1_000_000, isPaid: false),
        ]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.totalActiveObligations == 1)
    #expect(summary.totalOutstanding == 4_000_000)
    // June only.
    #expect(summary.currentMonthDue == 1_000_000)
    // June + July + August (window is [June start, September start)).
    #expect(summary.nextThreeMonthsDue == 3_000_000)
    #expect(summary.overdueAmount == 0)
}

@Test("build counts past unpaid installments as overdue")
func buildOverdueAmount() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let past = try makeDate(year: 2026, month: 6, day: 1, calendar: calendar)
    let future = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .homeCredit,
        purchaseName: "Late",
        totalAmount: 2_000_000,
        purchaseDate: past,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: past, amount: 1_200_000, isPaid: false),
            BNPLInstallment(dueDate: future, amount: 800_000, isPaid: false),
        ]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.overdueAmount == 1_200_000)
    // Past installment is before the reference, so the next future date is July 1.
    #expect(summary.nextInstallmentDate == future)
}

@Test("build computes exposure ratio relative to monthly income")
func buildExposureRatio() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jun = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .kredivo,
        purchaseName: "Ratio",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: jun, amount: 2_000_000, isPaid: false)]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 10_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(abs(summary.exposureRatio - 0.20) < 0.0001)
    #expect(summary.health == .overexposed)
}

@Test("build yields zero exposure ratio when income is zero")
func buildExposureRatioZeroIncome() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jun = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .kredivo,
        purchaseName: "NoIncome",
        totalAmount: 1_000_000,
        purchaseDate: reference,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: jun, amount: 1_000_000, isPaid: false)]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 0,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.exposureRatio == 0)
    #expect(summary.health == .critical)
}

@Test("build excludes paid installments from all aggregates")
func buildExcludesPaidInstallments() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jun = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
    let jul = try makeDate(year: 2026, month: 7, day: 20, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .atome,
        purchaseName: "PartlyPaid",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 2,
        installments: [
            BNPLInstallment(dueDate: jun, amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: jul, amount: 1_000_000, isPaid: false),
        ]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.totalOutstanding == 1_000_000)
    #expect(summary.currentMonthDue == 0)
    #expect(summary.nextThreeMonthsDue == 1_000_000)
    #expect(summary.nextInstallmentDate == jul)
}

// MARK: - BNPLSummaryBuilder monthly exposures

@Test("build produces six monthly exposures starting at the current month")
func buildSixMonthlyExposures() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let summary = BNPLSummaryBuilder.build(
        obligations: [],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.monthlyExposures.count == 6)
    let ids = summary.monthlyExposures.map(\.id)
    #expect(ids == ["2026-06", "2026-07", "2026-08", "2026-09", "2026-10", "2026-11"])
}

@Test("build buckets installments into the correct monthly exposure")
func buildMonthlyExposureBuckets() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jul1 = try makeDate(year: 2026, month: 7, day: 5, calendar: calendar)
    let jul2 = try makeDate(year: 2026, month: 7, day: 25, calendar: calendar)
    let aug = try makeDate(year: 2026, month: 8, day: 5, calendar: calendar)
    let obligation = BNPLObligation(
        provider: .fundiin,
        purchaseName: "Buckets",
        totalAmount: 3_000_000,
        purchaseDate: reference,
        installmentCount: 3,
        installments: [
            BNPLInstallment(dueDate: jul1, amount: 500_000, isPaid: false),
            BNPLInstallment(dueDate: jul2, amount: 700_000, isPaid: false),
            BNPLInstallment(dueDate: aug, amount: 1_000_000, isPaid: false),
        ]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligation],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    let july = try #require(summary.monthlyExposures.first { $0.id == "2026-07" })
    #expect(july.totalDue == 1_200_000)
    #expect(july.installmentCount == 2)
    let august = try #require(summary.monthlyExposures.first { $0.id == "2026-08" })
    #expect(august.totalDue == 1_000_000)
    #expect(august.installmentCount == 1)
    let june = try #require(summary.monthlyExposures.first { $0.id == "2026-06" })
    #expect(june.totalDue == 0)
    #expect(june.installmentCount == 0)
}

@Test("build aggregates across multiple obligations")
func buildMultipleObligations() throws {
    let calendar = gregorian()
    let reference = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
    let jun = try makeDate(year: 2026, month: 6, day: 20, calendar: calendar)
    let obligationA = BNPLObligation(
        provider: .atome,
        purchaseName: "A",
        totalAmount: 1_000_000,
        purchaseDate: reference,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: jun, amount: 1_000_000, isPaid: false)]
    )
    let obligationB = BNPLObligation(
        provider: .kredivo,
        purchaseName: "B",
        totalAmount: 2_000_000,
        purchaseDate: reference,
        installmentCount: 1,
        installments: [BNPLInstallment(dueDate: jun, amount: 2_000_000, isPaid: false)]
    )
    let summary = BNPLSummaryBuilder.build(
        obligations: [obligationA, obligationB],
        monthlyIncome: 20_000_000,
        referenceDate: reference,
        calendar: calendar
    )
    #expect(summary.totalActiveObligations == 2)
    #expect(summary.totalOutstanding == 3_000_000)
    #expect(summary.currentMonthDue == 3_000_000)
}

// MARK: - BNPLSummary value type

@Test("BNPLSummary is Equatable across identical values")
func summaryEquatable() throws {
    let calendar = gregorian()
    let date = try makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
    let exposures = [BNPLMonthlyExposure(year: 2026, month: 6, totalDue: 0, installmentCount: 0)]
    let a = BNPLSummary(
        totalActiveObligations: 1,
        totalOutstanding: 1_000_000,
        currentMonthDue: 500_000,
        nextThreeMonthsDue: 1_000_000,
        overdueAmount: 0,
        health: .safe,
        exposureRatio: 0.05,
        monthlyExposures: exposures,
        nextInstallmentDate: date
    )
    let b = BNPLSummary(
        totalActiveObligations: 1,
        totalOutstanding: 1_000_000,
        currentMonthDue: 500_000,
        nextThreeMonthsDue: 1_000_000,
        overdueAmount: 0,
        health: .safe,
        exposureRatio: 0.05,
        monthlyExposures: exposures,
        nextInstallmentDate: date
    )
    #expect(a == b)
}
