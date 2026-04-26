import SwiftUI

public struct KasoCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Spacing.md)
            .background(
                Color.kaso.surfaceSecondary,
                in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            )
    }
}

#Preview("Light") {
    KasoCard {
        Text("Kaso")
            .font(.kaso.titleMedium)
    }
    .padding(Spacing.md)
}

#Preview("Dark") {
    KasoCard {
        Text("Kaso")
            .font(.kaso.titleMedium)
    }
    .padding(Spacing.md)
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    KasoCard {
        Text("Kaso")
            .font(.kaso.titleMedium)
    }
    .padding(Spacing.md)
    .environment(\.dynamicTypeSize, .accessibility1)
}
