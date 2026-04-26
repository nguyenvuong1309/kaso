import Foundation
import Testing
@testable import WealthDomain

@Test("computes net worth from assets minus liabilities")
func computesNetWorth() throws {
    let date = try fixedDate(year: 2026, month: 4, day: 26)
    let assets: [Asset] = [
        Asset(name: "Tiền mặt", type: .cash, currentValue: 5_000_000),
        Asset(name: "Tiết kiệm", type: .bankSavings, currentValue: 50_000_000),
        Asset(name: "Cổ phiếu", type: .investment, currentValue: 30_000_000),
    ]
    let liabilities: [Liability] = [
        Liability(name: "Vay xe", type: .autoLoan, principalRemaining: 10_000_000),
        Liability(name: "Thẻ tín dụng", type: .creditCard, principalRemaining: 2_500_000),
    ]

    let snapshot = NetWorthCalculator.snapshot(
        assets: assets,
        liabilities: liabilities,
        on: date
    )

    #expect(snapshot.totalAssets == 85_000_000)
    #expect(snapshot.totalLiabilities == 12_500_000)
    #expect(snapshot.netWorth == 72_500_000)
    #expect(snapshot.date == date)
}

@Test("ignores negative asset and liability values when computing net worth")
func ignoresNegativeValues() throws {
    let date = try fixedDate(year: 2026, month: 4, day: 26)
    let assets: [Asset] = [
        Asset(name: "Bug", type: .other, currentValue: -1_000_000),
        Asset(name: "OK", type: .cash, currentValue: 2_000_000),
    ]
    let liabilities: [Liability] = [
        Liability(name: "Bug", type: .other, principalRemaining: -500_000),
    ]

    let snapshot = NetWorthCalculator.snapshot(
        assets: assets,
        liabilities: liabilities,
        on: date
    )

    #expect(snapshot.totalAssets == 2_000_000)
    #expect(snapshot.totalLiabilities == 0)
    #expect(snapshot.netWorth == 2_000_000)
}

@Test("growth comparison reports absolute and percent delta")
func growthDelta() throws {
    let previous = NetWorthSnapshot(
        date: try fixedDate(year: 2026, month: 3, day: 1),
        totalAssets: 100_000_000,
        totalLiabilities: 20_000_000
    )
    let current = NetWorthSnapshot(
        date: try fixedDate(year: 2026, month: 4, day: 1),
        totalAssets: 120_000_000,
        totalLiabilities: 20_000_000
    )

    let growth = current.growth(comparedTo: previous)

    #expect(growth.hasBaseline)
    #expect(growth.absoluteDelta == 20_000_000)
    #expect(growth.percentDelta == 0.25)
    #expect(growth.isPositive)
}

@Test("growth has no baseline when previous is missing")
func growthWithoutBaseline() throws {
    let current = NetWorthSnapshot(
        date: try fixedDate(year: 2026, month: 4, day: 1),
        totalAssets: 50_000_000,
        totalLiabilities: 0
    )

    let growth = current.growth(comparedTo: nil)

    #expect(growth.hasBaseline == false)
    #expect(growth.absoluteDelta == 0)
    #expect(growth.percentDelta == 0)
}

@Test("monthly history fills missing months by carrying forward last snapshot")
func monthlyHistoryCarriesForward() throws {
    let calendar = fixedCalendar()
    let snapshots: [NetWorthSnapshot] = [
        NetWorthSnapshot(
            date: try fixedDate(year: 2026, month: 1, day: 5),
            totalAssets: 60_000_000,
            totalLiabilities: 10_000_000
        ),
        NetWorthSnapshot(
            date: try fixedDate(year: 2026, month: 3, day: 20),
            totalAssets: 80_000_000,
            totalLiabilities: 5_000_000
        ),
    ]

    let history = NetWorthCalculator.monthlyHistory(
        recordedSnapshots: snapshots,
        through: try fixedDate(year: 2026, month: 4, day: 26),
        monthCount: 4,
        calendar: calendar
    )

    #expect(history.count == 4)
    #expect(history[0].netWorth == 50_000_000)
    #expect(history[1].netWorth == 50_000_000)
    #expect(history[2].netWorth == 75_000_000)
    #expect(history[3].netWorth == 75_000_000)
}

@Test("monthly history returns empty when month count is zero")
func monthlyHistoryEmpty() throws {
    let history = NetWorthCalculator.monthlyHistory(
        recordedSnapshots: [],
        through: try fixedDate(year: 2026, month: 4, day: 26),
        monthCount: 0,
        calendar: fixedCalendar()
    )

    #expect(history.isEmpty)
}

@Test("breakdown groups assets and liabilities by type with descending fraction")
func breakdownGroupsByType() throws {
    let assets: [Asset] = [
        Asset(name: "Tiền mặt", type: .cash, currentValue: 4_000_000),
        Asset(name: "Tiền mặt 2", type: .cash, currentValue: 1_000_000),
        Asset(name: "Tiết kiệm", type: .bankSavings, currentValue: 15_000_000),
    ]
    let liabilities: [Liability] = [
        Liability(name: "Thẻ", type: .creditCard, principalRemaining: 3_000_000),
    ]

    let breakdown = NetWorthBreakdownBuilder.make(
        assets: assets,
        liabilities: liabilities
    )

    #expect(breakdown.assetItems.count == 2)
    #expect(breakdown.assetItems[0].amount == 15_000_000)
    #expect(breakdown.assetItems[0].fraction == 0.75)
    #expect(breakdown.assetItems[1].amount == 5_000_000)
    #expect(breakdown.assetItems[1].fraction == 0.25)

    #expect(breakdown.liabilityItems.count == 1)
    #expect(breakdown.liabilityItems[0].amount == 3_000_000)
    #expect(breakdown.liabilityItems[0].fraction == 1.0)
}

@Test("asset draft validation reports name and value errors")
func assetDraftValidation() throws {
    let invalidDraft = AssetDraft(
        name: "   ",
        type: .cash,
        currentValue: -100
    )

    #expect(
        invalidDraft.validationErrors() == [
            .nameRequired,
            .currentValueCannotBeNegative,
        ]
    )

    do {
        _ = try invalidDraft.validated()
        Issue.record("Invalid asset draft should throw")
    } catch let error as AssetValidationError {
        #expect(error == .nameRequired)
    }
}

@Test("asset draft validates and trims whitespace")
func assetDraftValidatesValid() throws {
    let id = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000010"))
    let draft = AssetDraft(
        name: "  Tiết kiệm BIDV  ",
        type: .bankSavings,
        currentValue: 25_000_000,
        note: "  online  "
    )

    let asset = try draft.validated(id: id, lastUpdatedAt: Date(timeIntervalSinceReferenceDate: 0))

    #expect(asset.id == id)
    #expect(asset.name == "Tiết kiệm BIDV")
    #expect(asset.note == "online")
    #expect(asset.currentValue == 25_000_000)
}

@Test("liability draft validation rejects negative principal and empty name")
func liabilityDraftValidation() throws {
    let draft = LiabilityDraft(
        name: "",
        type: .creditCard,
        principalRemaining: -1
    )

    #expect(
        draft.validationErrors() == [
            .nameRequired,
            .principalCannotBeNegative,
        ]
    )
}

@Test("liability draft updating preserves id and auto-tracking flag")
func liabilityDraftUpdatingPreservesIdentity() throws {
    let existing = Liability(
        id: try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000020")),
        name: "Khoản cũ",
        type: .mortgage,
        principalRemaining: 500_000_000,
        isAutoTracked: true
    )
    let draft = LiabilityDraft(
        name: "Khoản đã cập nhật",
        type: .mortgage,
        principalRemaining: 480_000_000
    )

    let updated = try draft.updating(existing: existing)

    #expect(updated.id == existing.id)
    #expect(updated.name == "Khoản đã cập nhật")
    #expect(updated.principalRemaining == 480_000_000)
    #expect(updated.isAutoTracked == true)
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

private func fixedDate(year: Int, month: Int, day: Int) throws -> Date {
    try #require(
        DateComponents(
            calendar: fixedCalendar(),
            year: year,
            month: month,
            day: day
        ).date
    )
}
