import Foundation
import Testing
@testable import MoodJournalDomain

@Test("all cases are present and stable")
func moodAllCasesPresent() {
    #expect(Mood.allCases == [.great, .good, .neutral, .stressed, .sad, .anxious])
    #expect(Mood.allCases.count == 6)
}

@Test("id equals raw value for every case")
func moodIDMatchesRawValue() {
    for mood in Mood.allCases {
        #expect(mood.id == mood.rawValue)
    }
    #expect(Mood.great.id == "great")
    #expect(Mood.anxious.id == "anxious")
}

@Test("nameKey is namespaced with mood prefix")
func moodNameKeyNamespaced() {
    #expect(Mood.great.nameKey == "mood.great")
    #expect(Mood.good.nameKey == "mood.good")
    #expect(Mood.neutral.nameKey == "mood.neutral")
    #expect(Mood.stressed.nameKey == "mood.stressed")
    #expect(Mood.sad.nameKey == "mood.sad")
    #expect(Mood.anxious.nameKey == "mood.anxious")
}

@Test("emoji is distinct and non-empty for each case")
func moodEmojiDistinct() {
    let emojis = Mood.allCases.map(\.emoji)
    #expect(emojis.allSatisfy { $0.isEmpty == false })
    #expect(Set(emojis).count == Mood.allCases.count)
    #expect(Mood.great.emoji == "😄")
    #expect(Mood.good.emoji == "🙂")
    #expect(Mood.neutral.emoji == "😐")
    #expect(Mood.stressed.emoji == "😣")
    #expect(Mood.sad.emoji == "😔")
    #expect(Mood.anxious.emoji == "😟")
}

@Test("positivity score matches the defined scale")
func moodPositivityScore() {
    #expect(Mood.great.positivityScore == 1.0)
    #expect(Mood.good.positivityScore == 0.6)
    #expect(Mood.neutral.positivityScore == 0.0)
    #expect(Mood.stressed.positivityScore == -0.5)
    #expect(Mood.sad.positivityScore == -0.7)
    #expect(Mood.anxious.positivityScore == -0.6)
}

@Test("isNegative is true only when positivity score is below zero")
func moodIsNegative() {
    #expect(Mood.great.isNegative == false)
    #expect(Mood.good.isNegative == false)
    #expect(Mood.neutral.isNegative == false)
    #expect(Mood.stressed.isNegative == true)
    #expect(Mood.sad.isNegative == true)
    #expect(Mood.anxious.isNegative == true)
}

@Test("neutral is neither negative nor strictly positive")
func moodNeutralIsBoundary() {
    #expect(Mood.neutral.isNegative == false)
    #expect(Mood.neutral.positivityScore > 0 == false)
}

@Test("codable round-trip preserves each case")
func moodCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for mood in Mood.allCases {
        let data = try encoder.encode(mood)
        let decoded = try decoder.decode(Mood.self, from: data)
        #expect(decoded == mood)
    }
}

@Test("decodes from its raw string value")
func moodDecodesFromRawString() throws {
    let data = Data("\"stressed\"".utf8)
    let decoded = try JSONDecoder().decode(Mood.self, from: data)
    #expect(decoded == .stressed)
}
