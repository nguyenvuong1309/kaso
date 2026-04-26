public enum AppearanceMode: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String {
        rawValue
    }
}

public enum AccentColorOption: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case mint
    case blue
    case purple
    case orange
    case pink

    public var id: String {
        rawValue
    }
}

public struct AppearanceSettings: Codable, Equatable, Sendable {
    public static let defaultValue = AppearanceSettings()

    public var mode: AppearanceMode
    public var accentColor: AccentColorOption

    public init(
        mode: AppearanceMode = .system,
        accentColor: AccentColorOption = .mint
    ) {
        self.mode = mode
        self.accentColor = accentColor
    }
}
