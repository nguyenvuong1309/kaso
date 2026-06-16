import Foundation
import Testing
@testable import InsightDomain

@Test("forecast status exposes title and description keys")
func forecastStatusKeys() {
    #expect(MonthlyBalanceForecastStatus.safe.titleKey == "insight.forecast.safe.title")
    #expect(MonthlyBalanceForecastStatus.safe.descriptionKey == "insight.forecast.safe.description")
    #expect(MonthlyBalanceForecastStatus.tight.titleKey == "insight.forecast.tight.title")
    #expect(MonthlyBalanceForecastStatus.negative.descriptionKey == "insight.forecast.negative.description")
}

@Test("forecast status round-trips through Codable")
func forecastStatusRoundTrips() throws {
    for status in [MonthlyBalanceForecastStatus.safe, .tight, .negative] {
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(MonthlyBalanceForecastStatus.self, from: data)
        #expect(decoded == status)
    }
}

@Test("forecast stores all initialized fields")
func forecastStoresFields() {
    let forecast = MonthlyBalanceForecast(
        incomeToDate: 10_000_000,
        expenseToDate: 3_000_000,
        projectedExpense: 6_000_000,
        projectedBalance: 4_000_000,
        dailyExpenseRate: 200_000,
        remainingDayCount: 15,
        status: .safe
    )
    #expect(forecast.incomeToDate == 10_000_000)
    #expect(forecast.expenseToDate == 3_000_000)
    #expect(forecast.projectedExpense == 6_000_000)
    #expect(forecast.projectedBalance == 4_000_000)
    #expect(forecast.dailyExpenseRate == 200_000)
    #expect(forecast.remainingDayCount == 15)
    #expect(forecast.status == .safe)
}

@Test("forecasts with identical fields are equal")
func forecastEquality() {
    let lhs = MonthlyBalanceForecast(
        incomeToDate: 1, expenseToDate: 2, projectedExpense: 3,
        projectedBalance: 4, dailyExpenseRate: 5, remainingDayCount: 6, status: .tight
    )
    let rhs = MonthlyBalanceForecast(
        incomeToDate: 1, expenseToDate: 2, projectedExpense: 3,
        projectedBalance: 4, dailyExpenseRate: 5, remainingDayCount: 6, status: .tight
    )
    #expect(lhs == rhs)
}
