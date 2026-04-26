import Testing
@testable import AppearanceDomain

@Test("default appearance follows system with mint accent")
func defaultAppearanceFollowsSystemWithMintAccent() {
    #expect(AppearanceSettings.defaultValue.mode == .system)
    #expect(AppearanceSettings.defaultValue.accentColor == .mint)
}
