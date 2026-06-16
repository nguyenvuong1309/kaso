import Foundation
import Testing
@testable import FutureSelfDomain

struct FutureSelfLetterTests {
    @Test("tone emoji maps each case correctly")
    func toneEmoji() {
        #expect(FutureSelfTone.optimistic.emoji == "🌅")
        #expect(FutureSelfTone.steady.emoji == "🌤️")
        #expect(FutureSelfTone.cautionary.emoji == "🌧️")
    }

    @Test("tone headlineKey embeds raw value")
    func toneHeadlineKey() {
        #expect(FutureSelfTone.optimistic.headlineKey == "futureSelf.tone.optimistic.headline")
        #expect(FutureSelfTone.steady.headlineKey == "futureSelf.tone.steady.headline")
        #expect(FutureSelfTone.cautionary.headlineKey == "futureSelf.tone.cautionary.headline")
    }

    @Test("tone raw values are stable identifiers")
    func toneRawValues() {
        #expect(FutureSelfTone.optimistic.rawValue == "optimistic")
        #expect(FutureSelfTone.steady.rawValue == "steady")
        #expect(FutureSelfTone.cautionary.rawValue == "cautionary")
    }

    @Test("tone decodes from raw value")
    func toneDecode() throws {
        let json = Data("\"cautionary\"".utf8)
        let decoded = try JSONDecoder().decode(FutureSelfTone.self, from: json)
        #expect(decoded == .cautionary)
    }

    @Test("tone encode then decode round-trips")
    func toneCodableRoundTrip() throws {
        for tone in [FutureSelfTone.optimistic, .steady, .cautionary] {
            let data = try JSONEncoder().encode(tone)
            let decoded = try JSONDecoder().decode(FutureSelfTone.self, from: data)
            #expect(decoded == tone)
        }
    }

    @Test("letter init stores all fields")
    func letterInit() throws {
        let calendar = Calendar(identifier: .gregorian)
        let generated = try makeDate(year: 2026, month: 6, day: 16, calendar: calendar)
        let letter = FutureSelfLetter(
            quarterLabel: "Q2 2026",
            tone: .optimistic,
            projectedAge: 58,
            projectedAnnualSavings: 12_000_000,
            paragraphKeys: ["a", "b"],
            savingsRate: 0.3,
            generatedAt: generated,
            isSufficient: true
        )
        #expect(letter.quarterLabel == "Q2 2026")
        #expect(letter.tone == .optimistic)
        #expect(letter.projectedAge == 58)
        #expect(letter.projectedAnnualSavings == 12_000_000)
        #expect(letter.paragraphKeys == ["a", "b"])
        #expect(letter.savingsRate == 0.3)
        #expect(letter.generatedAt == generated)
        #expect(letter.isSufficient == true)
    }

    @Test("empty letter has neutral defaults")
    func emptyLetter() {
        let empty = FutureSelfLetter.empty
        #expect(empty.quarterLabel == "")
        #expect(empty.tone == .steady)
        #expect(empty.projectedAge == 0)
        #expect(empty.projectedAnnualSavings == 0)
        #expect(empty.paragraphKeys.isEmpty)
        #expect(empty.savingsRate == 0)
        #expect(empty.generatedAt == Date(timeIntervalSinceReferenceDate: 0))
        #expect(empty.isSufficient == false)
    }

    @Test("letters with identical fields are equal")
    func letterEquatable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let generated = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let lhs = FutureSelfLetter(
            quarterLabel: "Q1 2026",
            tone: .steady,
            projectedAge: 60,
            projectedAnnualSavings: 0,
            paragraphKeys: ["x"],
            savingsRate: 0.1,
            generatedAt: generated,
            isSufficient: true
        )
        let rhs = FutureSelfLetter(
            quarterLabel: "Q1 2026",
            tone: .steady,
            projectedAge: 60,
            projectedAnnualSavings: 0,
            paragraphKeys: ["x"],
            savingsRate: 0.1,
            generatedAt: generated,
            isSufficient: true
        )
        #expect(lhs == rhs)
    }

    @Test("letters differing in a single field are unequal")
    func letterInequality() throws {
        let calendar = Calendar(identifier: .gregorian)
        let generated = try makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        let base = FutureSelfLetter(
            quarterLabel: "Q1 2026",
            tone: .steady,
            projectedAge: 60,
            projectedAnnualSavings: 0,
            paragraphKeys: ["x"],
            savingsRate: 0.1,
            generatedAt: generated,
            isSufficient: true
        )
        let changedTone = FutureSelfLetter(
            quarterLabel: "Q1 2026",
            tone: .optimistic,
            projectedAge: 60,
            projectedAnnualSavings: 0,
            paragraphKeys: ["x"],
            savingsRate: 0.1,
            generatedAt: generated,
            isSufficient: true
        )
        #expect(base != changedTone)
    }
}

private func makeDate(
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
