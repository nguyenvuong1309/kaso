import Foundation
import Testing
@testable import MoneyPersonalityDomain

struct MoneyPersonalityTypeTests {
    @Test("allCases contains every personality type")
    func allCasesComplete() {
        let all = MoneyPersonalityType.allCases
        #expect(all.count == 5)
        #expect(Set(all) == Set([.planner, .impulsive, .minimalist, .foodie, .experienceSeeker]))
    }

    @Test("id matches rawValue for every case")
    func idMatchesRawValue() {
        for type in MoneyPersonalityType.allCases {
            #expect(type.id == type.rawValue)
        }
    }

    @Test("rawValue strings are stable")
    func rawValues() {
        #expect(MoneyPersonalityType.planner.rawValue == "planner")
        #expect(MoneyPersonalityType.impulsive.rawValue == "impulsive")
        #expect(MoneyPersonalityType.minimalist.rawValue == "minimalist")
        #expect(MoneyPersonalityType.foodie.rawValue == "foodie")
        #expect(MoneyPersonalityType.experienceSeeker.rawValue == "experienceSeeker")
    }

    @Test("localization keys are namespaced by rawValue")
    func localizationKeys() {
        for type in MoneyPersonalityType.allCases {
            #expect(type.nameKey == "personality.type.\(type.rawValue).name")
            #expect(type.taglineKey == "personality.type.\(type.rawValue).tagline")
            #expect(type.descriptionKey == "personality.type.\(type.rawValue).description")
            #expect(type.adviceKey == "personality.type.\(type.rawValue).advice")
        }
    }

    @Test("emoji is unique and non-empty per type")
    func emojiValues() {
        #expect(MoneyPersonalityType.planner.emoji == "🎯")
        #expect(MoneyPersonalityType.impulsive.emoji == "⚡")
        #expect(MoneyPersonalityType.minimalist.emoji == "🧘")
        #expect(MoneyPersonalityType.foodie.emoji == "🍜")
        #expect(MoneyPersonalityType.experienceSeeker.emoji == "🌍")

        let emojis = MoneyPersonalityType.allCases.map(\.emoji)
        #expect(Set(emojis).count == emojis.count)
    }

    @Test("symbolName is unique and non-empty per type")
    func symbolNames() {
        #expect(MoneyPersonalityType.planner.symbolName == "list.bullet.rectangle")
        #expect(MoneyPersonalityType.impulsive.symbolName == "bolt.fill")
        #expect(MoneyPersonalityType.minimalist.symbolName == "leaf.fill")
        #expect(MoneyPersonalityType.foodie.symbolName == "fork.knife")
        #expect(MoneyPersonalityType.experienceSeeker.symbolName == "airplane")

        let symbols = MoneyPersonalityType.allCases.map(\.symbolName)
        #expect(Set(symbols).count == symbols.count)
    }

    @Test("primary color hex values are correct and unique")
    func primaryColorHex() {
        #expect(MoneyPersonalityType.planner.primaryColorHex == "#4A90E2")
        #expect(MoneyPersonalityType.impulsive.primaryColorHex == "#F5A623")
        #expect(MoneyPersonalityType.minimalist.primaryColorHex == "#7ED321")
        #expect(MoneyPersonalityType.foodie.primaryColorHex == "#D0021B")
        #expect(MoneyPersonalityType.experienceSeeker.primaryColorHex == "#9013FE")

        let hexes = MoneyPersonalityType.allCases.map(\.primaryColorHex)
        #expect(Set(hexes).count == hexes.count)
    }

    @Test("secondary color hex values are correct and unique")
    func secondaryColorHex() {
        #expect(MoneyPersonalityType.planner.secondaryColorHex == "#50E3C2")
        #expect(MoneyPersonalityType.impulsive.secondaryColorHex == "#FFD400")
        #expect(MoneyPersonalityType.minimalist.secondaryColorHex == "#B8E986")
        #expect(MoneyPersonalityType.foodie.secondaryColorHex == "#F87171")
        #expect(MoneyPersonalityType.experienceSeeker.secondaryColorHex == "#BD10E0")

        let hexes = MoneyPersonalityType.allCases.map(\.secondaryColorHex)
        #expect(Set(hexes).count == hexes.count)
    }

    @Test("Codable round-trip preserves the case")
    func codableRoundTrip() throws {
        for type in MoneyPersonalityType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(MoneyPersonalityType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("decodes from rawValue JSON string")
    func decodeFromRawValue() throws {
        let data = Data("\"foodie\"".utf8)
        let decoded = try JSONDecoder().decode(MoneyPersonalityType.self, from: data)
        #expect(decoded == .foodie)
    }
}
