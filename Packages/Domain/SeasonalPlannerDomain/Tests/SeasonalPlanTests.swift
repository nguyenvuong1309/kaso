import Foundation
import Testing
@testable import SeasonalPlannerDomain

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

// MARK: - SeasonalSpike

@Test("extraVsBaseline returns positive difference when historical exceeds baseline")
func spikeExtraPositive() {
    let spike = SeasonalSpike(
        monthIndex: 2,
        nameKey: "seasonal.name.tet",
        historicalAverage: 9_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 2,
        weeksUntil: 4,
        suggestedWeeklySaving: 1_500_000
    )
    #expect(spike.extraVsBaseline == 6_000_000)
}

@Test("extraVsBaseline clamps to zero when baseline exceeds historical")
func spikeExtraClampsToZero() {
    let spike = SeasonalSpike(
        monthIndex: 5,
        nameKey: "seasonal.name.general",
        historicalAverage: 1_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 1,
        weeksUntil: 10,
        suggestedWeeklySaving: 0
    )
    #expect(spike.extraVsBaseline == 0)
}

@Test("extraVsBaseline is zero when historical equals baseline")
func spikeExtraZeroWhenEqual() {
    let spike = SeasonalSpike(
        monthIndex: 7,
        nameKey: "seasonal.name.general",
        historicalAverage: 2_500_000,
        baselineAverage: 2_500_000,
        yearsObserved: 3,
        weeksUntil: 0,
        suggestedWeeklySaving: 0
    )
    #expect(spike.extraVsBaseline == 0)
}

@Test("id mirrors monthIndex")
func spikeIdMirrorsMonthIndex() {
    let spike = SeasonalSpike(
        monthIndex: 11,
        nameKey: "seasonal.name.shopping",
        historicalAverage: 5_000_000,
        baselineAverage: 2_000_000,
        yearsObserved: 2,
        weeksUntil: 3,
        suggestedWeeklySaving: 1_000_000
    )
    #expect(spike.id == 11)
    #expect(spike.id == spike.monthIndex)
}

@Test("spike stores all initializer values verbatim")
func spikeStoresValues() {
    let spike = SeasonalSpike(
        monthIndex: 12,
        nameKey: "seasonal.name.yearEnd",
        historicalAverage: 8_000_000,
        baselineAverage: 4_000_000,
        yearsObserved: 4,
        weeksUntil: 6,
        suggestedWeeklySaving: 666_666
    )
    #expect(spike.monthIndex == 12)
    #expect(spike.nameKey == "seasonal.name.yearEnd")
    #expect(spike.historicalAverage == 8_000_000)
    #expect(spike.baselineAverage == 4_000_000)
    #expect(spike.yearsObserved == 4)
    #expect(spike.weeksUntil == 6)
    #expect(spike.suggestedWeeklySaving == 666_666)
}

@Test("spike equality distinguishes differing fields")
func spikeEquality() {
    let a = SeasonalSpike(
        monthIndex: 2,
        nameKey: "seasonal.name.tet",
        historicalAverage: 9_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 2,
        weeksUntil: 4,
        suggestedWeeklySaving: 1_500_000
    )
    let b = SeasonalSpike(
        monthIndex: 2,
        nameKey: "seasonal.name.tet",
        historicalAverage: 9_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 2,
        weeksUntil: 4,
        suggestedWeeklySaving: 1_500_000
    )
    let c = SeasonalSpike(
        monthIndex: 2,
        nameKey: "seasonal.name.tet",
        historicalAverage: 9_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 2,
        weeksUntil: 5,
        suggestedWeeklySaving: 1_500_000
    )
    #expect(a == b)
    #expect(a != c)
}

// MARK: - SeasonalPlan

@Test("empty plan has no spikes and is not sufficient")
func emptyPlan() {
    let plan = SeasonalPlan.empty
    #expect(plan.spikes.isEmpty)
    #expect(plan.isSufficient == false)
    #expect(plan.generatedAt == Date(timeIntervalSinceReferenceDate: 0))
}

@Test("plan stores initializer values and supports equality")
func planInitAndEquality() throws {
    let generatedAt = try makeDate(year: 2026, month: 6, day: 16)
    let spike = SeasonalSpike(
        monthIndex: 1,
        nameKey: "seasonal.name.tet",
        historicalAverage: 9_000_000,
        baselineAverage: 3_000_000,
        yearsObserved: 2,
        weeksUntil: 2,
        suggestedWeeklySaving: 3_000_000
    )
    let plan = SeasonalPlan(spikes: [spike], generatedAt: generatedAt, isSufficient: true)
    #expect(plan.spikes == [spike])
    #expect(plan.generatedAt == generatedAt)
    #expect(plan.isSufficient)

    let same = SeasonalPlan(spikes: [spike], generatedAt: generatedAt, isSufficient: true)
    #expect(plan == same)

    let different = SeasonalPlan(spikes: [], generatedAt: generatedAt, isSufficient: true)
    #expect(plan != different)
}

// MARK: - SeasonalMonthName

@Test("month name keys map to hyperlocal Vietnamese seasons")
func monthNameKeys() {
    #expect(SeasonalMonthName.key(forMonth: 1) == "seasonal.name.tet")
    #expect(SeasonalMonthName.key(forMonth: 2) == "seasonal.name.tet")
    #expect(SeasonalMonthName.key(forMonth: 8) == "seasonal.name.backToSchool")
    #expect(SeasonalMonthName.key(forMonth: 9) == "seasonal.name.backToSchool")
    #expect(SeasonalMonthName.key(forMonth: 11) == "seasonal.name.shopping")
    #expect(SeasonalMonthName.key(forMonth: 12) == "seasonal.name.yearEnd")
}

@Test("non-seasonal months fall back to general key")
func monthNameGeneralFallback() {
    for month in [3, 4, 5, 6, 7, 10] {
        #expect(SeasonalMonthName.key(forMonth: month) == "seasonal.name.general")
    }
}

@Test("out-of-range month indices fall back to general key")
func monthNameOutOfRange() {
    #expect(SeasonalMonthName.key(forMonth: 0) == "seasonal.name.general")
    #expect(SeasonalMonthName.key(forMonth: 13) == "seasonal.name.general")
    #expect(SeasonalMonthName.key(forMonth: -1) == "seasonal.name.general")
}
