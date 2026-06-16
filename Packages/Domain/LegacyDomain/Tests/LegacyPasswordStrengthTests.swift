import Foundation
import Testing
@testable import LegacyDomain

// MARK: - weak

@Test("empty password is weak")
func emptyPasswordIsWeak() {
    #expect(LegacyPasswordStrength.evaluate("") == .weak)
}

@Test("short password is weak")
func shortPasswordIsWeak() {
    #expect(LegacyPasswordStrength.evaluate("abc") == .weak)
    #expect(LegacyPasswordStrength.evaluate("Ab1!") == .weak)
}

@Test("eight character password without number is weak")
func eightCharsNoNumberIsWeak() {
    // 8 chars, letters only -> fails fair (needs number) and strong
    #expect(LegacyPasswordStrength.evaluate("abcdefgh") == .weak)
}

@Test("number-only eight chars is weak because no letter case")
func numberOnlyEightCharsIsWeak() {
    // hasNumber true but neither lowercase nor uppercase -> fair fails
    #expect(LegacyPasswordStrength.evaluate("12345678") == .weak)
}

// MARK: - fair (boundary: count >= 8, hasNumber, has lower OR upper)

@Test("eight char lowercase with number is fair")
func eightCharLowercaseNumberIsFair() {
    #expect(LegacyPasswordStrength.evaluate("abcdefg1") == .fair)
}

@Test("eight char uppercase with number is fair")
func eightCharUppercaseNumberIsFair() {
    #expect(LegacyPasswordStrength.evaluate("ABCDEFG1") == .fair)
}

@Test("seven char with number falls to weak (below fair boundary)")
func sevenCharIsWeak() {
    #expect(LegacyPasswordStrength.evaluate("abcde1f") == .weak)
}

@Test("nine char missing symbol is fair not strong")
func nineCharMissingSymbolIsFair() {
    // 9 chars, upper, lower, number, but no symbol -> not strong, falls to fair
    #expect(LegacyPasswordStrength.evaluate("Abcdefg12") == .fair)
}

@Test("nine char missing uppercase with symbol is fair not strong")
func nineCharMissingUppercaseIsFair() {
    // strong needs uppercase; this has lower+number+symbol at len 9 -> fair
    #expect(LegacyPasswordStrength.evaluate("abcdefg1!") == .fair)
}

// MARK: - strong (boundary: count >= 9 + all four classes)

@Test("nine char with all classes is strong")
func nineCharAllClassesIsStrong() {
    #expect(LegacyPasswordStrength.evaluate("Abcdef12!") == .strong)
}

@Test("long password with all classes is strong")
func longPasswordAllClassesIsStrong() {
    #expect(LegacyPasswordStrength.evaluate("SuperSecure123!@#") == .strong)
}

@Test("eight char with all classes is fair not strong (length boundary)")
func eightCharAllClassesIsFair() {
    // All four classes but only 8 chars -> strong requires >= 9, falls to fair
    #expect(LegacyPasswordStrength.evaluate("Abc123!x") == .fair)
}

// MARK: - symbol detection edge

@Test("space counts as symbol for strength")
func spaceCountsAsSymbol() {
    // " " is not letter and not number -> symbol; 9 chars w/ all classes
    #expect(LegacyPasswordStrength.evaluate("Abcde 123") == .strong)
}

// MARK: - codable

@Test("password strength codable round trip")
func passwordStrengthCodableRoundTrip() throws {
    for strength in [LegacyPasswordStrength.weak, .fair, .strong] {
        let data = try JSONEncoder().encode(strength)
        let decoded = try JSONDecoder().decode(LegacyPasswordStrength.self, from: data)
        #expect(decoded == strength)
    }
}

@Test("password strength raw values are stable")
func passwordStrengthRawValues() {
    #expect(LegacyPasswordStrength.weak.rawValue == "weak")
    #expect(LegacyPasswordStrength.fair.rawValue == "fair")
    #expect(LegacyPasswordStrength.strong.rawValue == "strong")
}
