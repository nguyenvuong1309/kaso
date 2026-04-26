import SwiftUI

public enum KasoFontTokens {
    public static var titleLarge: Font {
        .system(.largeTitle, design: .rounded, weight: .bold)
    }

    public static var titleMedium: Font {
        .system(.title2, design: .rounded, weight: .semibold)
    }

    public static var body: Font {
        .system(.body, design: .rounded)
    }

    public static var caption: Font {
        .system(.caption, design: .rounded)
    }

    public static var numericLarge: Font {
        .system(.title, design: .rounded, weight: .bold)
        .monospacedDigit()
    }

    public static var numericMedium: Font {
        .system(.headline, design: .rounded, weight: .semibold)
        .monospacedDigit()
    }
}

public extension Font {
    static var kaso: KasoFontTokens.Type {
        KasoFontTokens.self
    }
}
