import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum KasoColorTokens {
    public static var surfacePrimary: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.clear
        #endif
    }

    public static var surfaceSecondary: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color.clear
        #endif
    }

    public static var textPrimary: Color {
        .primary
    }

    public static var textSecondary: Color {
        .secondary
    }

    public static var accent: Color {
        .accentColor
    }

    public static var positive: Color {
        .green
    }

    public static var warning: Color {
        .orange
    }

    public static var destructive: Color {
        .red
    }

    public static func accent(named name: String) -> Color {
        switch name {
        case "blue":
            .blue
        case "green":
            .green
        case "mint":
            .mint
        case "orange":
            .orange
        case "pink":
            .pink
        case "purple":
            .purple
        default:
            accent
        }
    }

    public static func category(named name: String) -> Color {
        switch name {
        case "blue":
            .blue
        case "brown":
            .brown
        case "gray":
            .gray
        case "green":
            .green
        case "indigo":
            .indigo
        case "mint":
            .mint
        case "orange":
            .orange
        case "pink":
            .pink
        case "purple":
            .purple
        case "red":
            .red
        default:
            accent
        }
    }
}

public extension Color {
    static var kaso: KasoColorTokens.Type {
        KasoColorTokens.self
    }
}
