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
}

public extension Color {
    static var kaso: KasoColorTokens.Type {
        KasoColorTokens.self
    }
}
