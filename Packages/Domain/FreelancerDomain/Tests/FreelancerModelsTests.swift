import Foundation
import Testing
@testable import FreelancerDomain

private func makeDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 0,
    calendar: Calendar = Calendar(identifier: .gregorian)
) throws -> Date {
    try #require(
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date
    )
}

private let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")

// MARK: - FreelancerWorkType

@Test("work type exposes raw value as id")
func workTypeID() {
    for workType in FreelancerWorkType.allCases {
        #expect(workType.id == workType.rawValue)
    }
}

@Test("work type builds localization key from raw value")
func workTypeTitleKey() {
    #expect(FreelancerWorkType.freelancer.titleKey == "freelancer.workType.freelancer")
    #expect(FreelancerWorkType.gigDriver.titleKey == "freelancer.workType.gigDriver")
    #expect(FreelancerWorkType.onlineSeller.titleKey == "freelancer.workType.onlineSeller")
    #expect(FreelancerWorkType.other.titleKey == "freelancer.workType.other")
}

@Test("work type enumerates all four cases")
func workTypeAllCases() {
    #expect(FreelancerWorkType.allCases.count == 4)
}

// MARK: - SmoothingWindow

@Test("smoothing window raw values map to month counts")
func smoothingWindowRawValues() {
    #expect(SmoothingWindow.threeMonths.rawValue == 3)
    #expect(SmoothingWindow.sixMonths.rawValue == 6)
    #expect(SmoothingWindow.twelveMonths.rawValue == 12)
}

@Test("smoothing window id equals raw value")
func smoothingWindowID() {
    for window in SmoothingWindow.allCases {
        #expect(window.id == window.rawValue)
    }
}

@Test("smoothing window provides distinct title keys")
func smoothingWindowTitleKeys() {
    #expect(SmoothingWindow.threeMonths.titleKey == "freelancer.window.three")
    #expect(SmoothingWindow.sixMonths.titleKey == "freelancer.window.six")
    #expect(SmoothingWindow.twelveMonths.titleKey == "freelancer.window.twelve")
}

// MARK: - IncomeDeductionCategory

@Test("deduction category id equals raw value and lists all cases")
func deductionCategoryBasics() {
    #expect(IncomeDeductionCategory.allCases.count == 5)
    for category in IncomeDeductionCategory.allCases {
        #expect(category.id == category.rawValue)
    }
}

// MARK: - IncomeDeduction

@Test("income deduction stores supplied values")
func incomeDeductionInit() throws {
    let id = try #require(fixedID)
    let deduction = IncomeDeduction(
        id: id,
        title: "Income tax",
        amount: 1_000_000,
        category: .tax
    )
    #expect(deduction.id == id)
    #expect(deduction.title == "Income tax")
    #expect(deduction.amount == 1_000_000)
    #expect(deduction.category == .tax)
}

@Test("income deduction codable round-trips")
func incomeDeductionCodable() throws {
    let id = try #require(fixedID)
    let original = IncomeDeduction(id: id, title: "Platform fee", amount: 250_000, category: .platformFee)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(IncomeDeduction.self, from: data)
    #expect(decoded == original)
}

// MARK: - MonthlyIncome

@Test("monthly income net amount subtracts positive deductions")
func monthlyIncomeNetSubtractsDeductions() {
    let income = MonthlyIncome(
        month: YearMonth(year: 2026, month: 4),
        grossAmount: 10_000_000,
        deductions: [
            IncomeDeduction(title: "Tax", amount: 1_000_000, category: .tax),
            IncomeDeduction(title: "Fee", amount: 500_000, category: .platformFee),
        ]
    )
    #expect(income.netAmount == 8_500_000)
}

@Test("monthly income net amount with no deductions equals gross")
func monthlyIncomeNetNoDeductions() {
    let income = MonthlyIncome(month: YearMonth(year: 2026, month: 4), grossAmount: 7_000_000)
    #expect(income.netAmount == 7_000_000)
    #expect(income.deductions.isEmpty)
}

@Test("monthly income net amount floors at zero when deductions exceed gross")
func monthlyIncomeNetFloorsAtZero() {
    let income = MonthlyIncome(
        month: YearMonth(year: 2026, month: 4),
        grossAmount: 1_000_000,
        deductions: [IncomeDeduction(title: "Tax", amount: 5_000_000, category: .tax)]
    )
    #expect(income.netAmount == 0)
}

@Test("monthly income ignores negative deduction amounts")
func monthlyIncomeNetIgnoresNegativeDeductions() {
    let income = MonthlyIncome(
        month: YearMonth(year: 2026, month: 4),
        grossAmount: 10_000_000,
        deductions: [
            IncomeDeduction(title: "Negative", amount: -2_000_000, category: .other),
            IncomeDeduction(title: "Tax", amount: 1_000_000, category: .tax),
        ]
    )
    #expect(income.netAmount == 9_000_000)
}

@Test("monthly income id is its month")
func monthlyIncomeID() {
    let month = YearMonth(year: 2026, month: 9)
    let income = MonthlyIncome(month: month, grossAmount: 5_000_000)
    #expect(income.id == month)
}

@Test("monthly income codable round-trips")
func monthlyIncomeCodable() throws {
    let id = try #require(fixedID)
    let original = MonthlyIncome(
        month: YearMonth(year: 2026, month: 2),
        grossAmount: 12_000_000,
        deductions: [IncomeDeduction(id: id, title: "Insurance", amount: 800_000, category: .insurance)]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(MonthlyIncome.self, from: data)
    #expect(decoded == original)
}

// MARK: - FreelancerProfile

@Test("freelancer profile applies default values")
func freelancerProfileDefaults() throws {
    let id = try #require(fixedID)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let updated = try makeDate(year: 2026, month: 6, day: 1)
    let profile = FreelancerProfile(id: id, createdAt: created, updatedAt: updated)
    #expect(profile.monthlyIncomes.isEmpty)
    #expect(profile.smoothingWindow == .threeMonths)
    #expect(profile.bufferBalance == 0)
    #expect(profile.bufferTargetMultiplier == 2)
    #expect(profile.workType == .freelancer)
    #expect(profile.taxRate == nil)
    #expect(profile.createdAt == created)
    #expect(profile.updatedAt == updated)
}

@Test("freelancer profile codable round-trips")
func freelancerProfileCodable() throws {
    let id = try #require(fixedID)
    let created = try makeDate(year: 2026, month: 1, day: 1)
    let updated = try makeDate(year: 2026, month: 6, day: 1)
    let original = FreelancerProfile(
        id: id,
        monthlyIncomes: [MonthlyIncome(month: YearMonth(year: 2026, month: 3), grossAmount: 9_000_000)],
        smoothingWindow: .sixMonths,
        bufferBalance: 4_000_000,
        bufferTargetMultiplier: 3,
        workType: .gigDriver,
        taxRate: 0.15,
        createdAt: created,
        updatedAt: updated
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(FreelancerProfile.self, from: data)
    #expect(decoded == original)
}

// MARK: - FreelancerSmoothedView

@Test("smoothed view stores all supplied fields")
func smoothedViewInit() {
    let view = FreelancerSmoothedView(
        smoothedMonthlyIncome: 10_000_000,
        currentMonthNetIncome: 8_000_000,
        bufferBalance: 20_000_000,
        bufferTarget: 20_000_000,
        bufferCoverage: 2,
        currentMonthSurplus: 0,
        currentMonthDeficit: 2_000_000,
        taxProvision: 1_000_000,
        window: .sixMonths,
        bufferStatus: .healthy
    )
    #expect(view.smoothedMonthlyIncome == 10_000_000)
    #expect(view.currentMonthNetIncome == 8_000_000)
    #expect(view.bufferBalance == 20_000_000)
    #expect(view.bufferTarget == 20_000_000)
    #expect(view.bufferCoverage == 2)
    #expect(view.currentMonthSurplus == 0)
    #expect(view.currentMonthDeficit == 2_000_000)
    #expect(view.taxProvision == 1_000_000)
    #expect(view.window == .sixMonths)
    #expect(view.bufferStatus == .healthy)
}

@Test("smoothed view codable round-trips")
func smoothedViewCodable() throws {
    let original = FreelancerSmoothedView(
        smoothedMonthlyIncome: 10_000_000,
        currentMonthNetIncome: 8_000_000,
        bufferBalance: 20_000_000,
        bufferTarget: 20_000_000,
        bufferCoverage: 2,
        currentMonthSurplus: 0,
        currentMonthDeficit: 2_000_000,
        taxProvision: 1_000_000,
        window: .twelveMonths,
        bufferStatus: .warning
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(FreelancerSmoothedView.self, from: data)
    #expect(decoded == original)
}

// MARK: - FreelancerReminder

@Test("tax deadline reminder builds a stable id")
func reminderTaxDeadlineID() throws {
    let dueDate = try makeDate(year: 2026, month: 4, day: 30)
    let reminder = FreelancerReminder.taxDeadline(amount: 1_500_000, dueDate: dueDate)
    let expected = "tax-1500000-\(dueDate.timeIntervalSinceReferenceDate)"
    #expect(reminder.id == expected)
}

@Test("insurance renewal reminder embeds provider in id")
func reminderInsuranceID() throws {
    let dueDate = try makeDate(year: 2026, month: 7, day: 1)
    let reminder = FreelancerReminder.insuranceRenewal(provider: "Bao Viet", dueDate: dueDate)
    let expected = "insurance-Bao Viet-\(dueDate.timeIntervalSinceReferenceDate)"
    #expect(reminder.id == expected)
}

@Test("low buffer reminder embeds months covered in id")
func reminderLowBufferID() {
    let reminder = FreelancerReminder.lowBuffer(monthsCovered: 0.5)
    #expect(reminder.id == "buffer-0.5")
}

@Test("slow season reminder embeds pattern in id")
func reminderSlowSeasonID() {
    let reminder = FreelancerReminder.slowSeasonAlert(historicalPattern: "q4-dip")
    #expect(reminder.id == "slow-q4-dip")
}

@Test("reminder codable round-trips for each case")
func reminderCodable() throws {
    let dueDate = try makeDate(year: 2026, month: 4, day: 30)
    let cases: [FreelancerReminder] = [
        .taxDeadline(amount: 1_500_000, dueDate: dueDate),
        .insuranceRenewal(provider: "Bao Viet", dueDate: dueDate),
        .lowBuffer(monthsCovered: 0.75),
        .slowSeasonAlert(historicalPattern: "pattern"),
    ]
    for original in cases {
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FreelancerReminder.self, from: data)
        #expect(decoded == original)
    }
}
