import Foundation
import Testing
@testable import AppearanceDomain

// MARK: - AppearanceMode

@Test("AppearanceMode declares all expected cases in order")
func appearanceModeCaseIterable() {
    #expect(AppearanceMode.allCases == [.system, .light, .dark])
}

@Test("AppearanceMode raw values are stable identifiers")
func appearanceModeRawValues() {
    #expect(AppearanceMode.system.rawValue == "system")
    #expect(AppearanceMode.light.rawValue == "light")
    #expect(AppearanceMode.dark.rawValue == "dark")
}

@Test("AppearanceMode id matches raw value for every case")
func appearanceModeIdMatchesRawValue() {
    for mode in AppearanceMode.allCases {
        #expect(mode.id == mode.rawValue)
    }
}

@Test("AppearanceMode initializes from raw value and rejects unknown")
func appearanceModeFromRawValue() {
    #expect(AppearanceMode(rawValue: "dark") == .dark)
    #expect(AppearanceMode(rawValue: "unknown") == nil)
}

@Test("AppearanceMode encodes and decodes round-trip for every case")
func appearanceModeCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for mode in AppearanceMode.allCases {
        let data = try encoder.encode(mode)
        let decoded = try decoder.decode(AppearanceMode.self, from: data)
        #expect(decoded == mode)
    }
}

// MARK: - AccentColorOption

@Test("AccentColorOption declares all expected cases in order")
func accentColorOptionCaseIterable() {
    #expect(AccentColorOption.allCases == [.mint, .blue, .purple, .orange, .pink])
}

@Test("AccentColorOption raw values are stable identifiers")
func accentColorOptionRawValues() {
    #expect(AccentColorOption.mint.rawValue == "mint")
    #expect(AccentColorOption.blue.rawValue == "blue")
    #expect(AccentColorOption.purple.rawValue == "purple")
    #expect(AccentColorOption.orange.rawValue == "orange")
    #expect(AccentColorOption.pink.rawValue == "pink")
}

@Test("AccentColorOption id matches raw value for every case")
func accentColorOptionIdMatchesRawValue() {
    for option in AccentColorOption.allCases {
        #expect(option.id == option.rawValue)
    }
}

@Test("AccentColorOption initializes from raw value and rejects unknown")
func accentColorOptionFromRawValue() {
    #expect(AccentColorOption(rawValue: "orange") == .orange)
    #expect(AccentColorOption(rawValue: "teal") == nil)
}

@Test("AccentColorOption encodes and decodes round-trip for every case")
func accentColorOptionCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for option in AccentColorOption.allCases {
        let data = try encoder.encode(option)
        let decoded = try decoder.decode(AccentColorOption.self, from: data)
        #expect(decoded == option)
    }
}

// MARK: - AppearanceSettings

@Test("AppearanceSettings init defaults to system mode and mint accent")
func appearanceSettingsInitDefaults() {
    let settings = AppearanceSettings()
    #expect(settings.mode == .system)
    #expect(settings.accentColor == .mint)
}

@Test("AppearanceSettings init honors explicit arguments")
func appearanceSettingsInitExplicit() {
    let settings = AppearanceSettings(mode: .dark, accentColor: .purple)
    #expect(settings.mode == .dark)
    #expect(settings.accentColor == .purple)
}

@Test("AppearanceSettings defaultValue equals a freshly defaulted instance")
func appearanceSettingsDefaultValueEquality() {
    #expect(AppearanceSettings.defaultValue == AppearanceSettings())
}

@Test("AppearanceSettings properties are mutable")
func appearanceSettingsMutability() {
    var settings = AppearanceSettings()
    settings.mode = .light
    settings.accentColor = .pink
    #expect(settings.mode == .light)
    #expect(settings.accentColor == .pink)
}

@Test("AppearanceSettings equality distinguishes mode and accent")
func appearanceSettingsEquality() {
    let base = AppearanceSettings(mode: .light, accentColor: .blue)
    #expect(base == AppearanceSettings(mode: .light, accentColor: .blue))
    #expect(base != AppearanceSettings(mode: .dark, accentColor: .blue))
    #expect(base != AppearanceSettings(mode: .light, accentColor: .orange))
}

@Test("AppearanceSettings encodes and decodes round-trip preserving values")
func appearanceSettingsCodableRoundTrip() throws {
    let original = AppearanceSettings(mode: .dark, accentColor: .orange)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AppearanceSettings.self, from: data)
    #expect(decoded == original)
}

@Test("AppearanceSettings decodes from explicit JSON keys")
func appearanceSettingsDecodeFromJSON() throws {
    let json = Data(#"{"mode":"light","accentColor":"pink"}"#.utf8)
    let decoded = try JSONDecoder().decode(AppearanceSettings.self, from: json)
    #expect(decoded.mode == .light)
    #expect(decoded.accentColor == .pink)
}
