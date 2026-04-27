import Foundation
import Testing
@testable import PhantomExpenseDomain

@Test("draft validates title and positive amount")
func draftValidatesTitleAndPositiveAmount() throws {
    let invalid = PhantomExpenseDraft(title: " ", amount: 0)

    #expect(
        Set(invalid.validationErrors()) == Set([
            .titleRequired,
            .amountMustBePositive,
        ])
    )

    let draft = PhantomExpenseDraft(
        title: "  Bỏ giỏ hàng sneaker  ",
        amount: 1_500_000,
        category: .cart,
        note: "  Sale cuối tháng  "
    )
    let expense = try draft.validated()

    #expect(expense.title == "Bỏ giỏ hàng sneaker")
    #expect(expense.note == "Sale cuối tháng")
}

@Test("monthly summary filters current month and groups by category")
func monthlySummaryFiltersAndGroups() throws {
    let aprilDate = try date(2026, 4, 20)
    let marchDate = try date(2026, 3, 20)
    let expenses = [
        PhantomExpense(title: "Huỷ subscription", amount: 300_000, category: .subscription, avoidedAt: aprilDate),
        PhantomExpense(title: "Bỏ giỏ hàng", amount: 700_000, category: .cart, avoidedAt: aprilDate),
        PhantomExpense(title: "Không mua game", amount: 200_000, category: .cart, avoidedAt: aprilDate),
        PhantomExpense(title: "Tháng trước", amount: 1_000_000, category: .trip, avoidedAt: marchDate),
    ]

    let summary = PhantomExpenseSummaryBuilder.monthly(
        expenses: expenses,
        referenceDate: aprilDate,
        calendar: fixedCalendar()
    )

    #expect(summary.count == 3)
    #expect(summary.totalAvoided == 1_200_000)
    #expect(summary.averageAvoided == 400_000)
    #expect(summary.categorySummaries.first?.category == .cart)
    #expect(summary.categorySummaries.first?.amount == 900_000)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
