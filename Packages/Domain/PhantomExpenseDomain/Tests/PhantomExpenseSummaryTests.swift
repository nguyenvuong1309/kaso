import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("category summary id equals its category")
func categorySummaryId() {
    let summary = PhantomExpenseCategorySummary(
        category: .cart,
        amount: 100,
        count: 2,
        fraction: 0.5
    )
    #expect(summary.id == .cart)
}

@Test("monthly summary empty constant has zeroed fields")
func monthlySummaryEmpty() {
    let summary = PhantomExpenseMonthlySummary.empty
    #expect(summary.expenses.isEmpty)
    #expect(summary.totalAvoided == 0)
    #expect(summary.categorySummaries.isEmpty)
    #expect(summary.count == 0)
}

@Test("monthly summary averageAvoided is zero when empty")
func averageAvoidedEmpty() {
    #expect(PhantomExpenseMonthlySummary.empty.averageAvoided == 0)
}

@Test("monthly summary count reflects expense array")
func monthlySummaryCount() {
    let summary = PhantomExpenseMonthlySummary(
        expenses: [
            PhantomExpense(title: "A", amount: 1),
            PhantomExpense(title: "B", amount: 2),
        ],
        totalAvoided: 3,
        categorySummaries: []
    )
    #expect(summary.count == 2)
}

@Test("monthly summary averageAvoided divides total by count")
func averageAvoidedComputed() {
    let summary = PhantomExpenseMonthlySummary(
        expenses: [
            PhantomExpense(title: "A", amount: 100),
            PhantomExpense(title: "B", amount: 200),
            PhantomExpense(title: "C", amount: 300),
        ],
        totalAvoided: 900,
        categorySummaries: []
    )
    #expect(summary.averageAvoided == 300)
}

@Test("builder returns empty summary for no expenses")
func builderEmptyInput() throws {
    let calendar = makeSummaryCalendar()
    let reference = try makeSummaryDate(year: 2026, month: 4, day: 15, calendar: calendar)

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: [],
        referenceDate: reference,
        calendar: calendar
    )

    #expect(summary.expenses.isEmpty)
    #expect(summary.totalAvoided == 0)
    #expect(summary.categorySummaries.isEmpty)
}

@Test("builder excludes expenses from other months and years")
func builderExcludesOtherMonths() throws {
    let calendar = makeSummaryCalendar()
    let reference = try makeSummaryDate(year: 2026, month: 4, day: 15, calendar: calendar)
    let sameMonthDifferentYear = try makeSummaryDate(year: 2025, month: 4, day: 15, calendar: calendar)
    let nextMonth = try makeSummaryDate(year: 2026, month: 5, day: 1, calendar: calendar)
    let inMonth = try makeSummaryDate(year: 2026, month: 4, day: 2, calendar: calendar)
    let expenses = [
        PhantomExpense(title: "In", amount: 100, avoidedAt: inMonth),
        PhantomExpense(title: "Year off", amount: 50, avoidedAt: sameMonthDifferentYear),
        PhantomExpense(title: "Month off", amount: 70, avoidedAt: nextMonth),
    ]

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: expenses,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(summary.count == 1)
    #expect(summary.totalAvoided == 100)
}

@Test("builder sorts expenses newest first")
func builderSortsExpensesDescending() throws {
    let calendar = makeSummaryCalendar()
    let reference = try makeSummaryDate(year: 2026, month: 4, day: 15, calendar: calendar)
    let early = try makeSummaryDate(year: 2026, month: 4, day: 1, calendar: calendar)
    let middle = try makeSummaryDate(year: 2026, month: 4, day: 10, calendar: calendar)
    let late = try makeSummaryDate(year: 2026, month: 4, day: 20, calendar: calendar)
    let expenses = [
        PhantomExpense(title: "Early", amount: 1, avoidedAt: early),
        PhantomExpense(title: "Late", amount: 1, avoidedAt: late),
        PhantomExpense(title: "Middle", amount: 1, avoidedAt: middle),
    ]

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: expenses,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(summary.expenses.map(\.title) == ["Late", "Middle", "Early"])
}

@Test("builder computes category fractions summing to one")
func builderCategoryFractions() throws {
    let calendar = makeSummaryCalendar()
    let reference = try makeSummaryDate(year: 2026, month: 4, day: 15, calendar: calendar)
    let date = try makeSummaryDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let expenses = [
        PhantomExpense(title: "Cart", amount: 600_000, category: .cart, avoidedAt: date),
        PhantomExpense(title: "Trip", amount: 400_000, category: .trip, avoidedAt: date),
    ]

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: expenses,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(summary.totalAvoided == 1_000_000)
    let cart = try #require(summary.categorySummaries.first { $0.category == .cart })
    let trip = try #require(summary.categorySummaries.first { $0.category == .trip })
    #expect(abs(cart.fraction - 0.6) < 0.0001)
    #expect(abs(trip.fraction - 0.4) < 0.0001)
    #expect(cart.count == 1)
    #expect(trip.count == 1)
}

@Test("builder sorts category summaries by amount descending")
func builderCategorySorting() throws {
    let calendar = makeSummaryCalendar()
    let reference = try makeSummaryDate(year: 2026, month: 4, day: 15, calendar: calendar)
    let date = try makeSummaryDate(year: 2026, month: 4, day: 5, calendar: calendar)
    let expenses = [
        PhantomExpense(title: "Small", amount: 100, category: .other, avoidedAt: date),
        PhantomExpense(title: "Big A", amount: 500, category: .cart, avoidedAt: date),
        PhantomExpense(title: "Big B", amount: 400, category: .cart, avoidedAt: date),
        PhantomExpense(title: "Medium", amount: 300, category: .trip, avoidedAt: date),
    ]

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: expenses,
        referenceDate: reference,
        calendar: calendar
    )

    #expect(summary.categorySummaries.map(\.category) == [.cart, .trip, .other])
    #expect(summary.categorySummaries.first?.amount == 900)
    #expect(summary.categorySummaries.first?.count == 2)
}

private func makeSummaryCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func makeSummaryDate(
    year: Int,
    month: Int,
    day: Int,
    hour: Int = 12,
    calendar: Calendar
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
