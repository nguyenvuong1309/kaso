import SwiftUI

/// A small corner ribbon marking a non-production build (e.g. "DEV"), so the
/// dev and prod apps are distinguishable at a glance when installed side by
/// side. Purely presentational — the caller decides the label and whether to
/// show it, keeping this module free of any app-configuration dependency.
public struct EnvironmentBadge: View {
    private let label: String

    public init(_ label: String) {
        self.label = label
    }

    public var body: some View {
        Text(label)
            .font(.kaso.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Color.kaso.warning,
                in: Capsule(style: .continuous)
            )
            .accessibilityLabel(Text("\(label) build"))
    }
}

private struct EnvironmentBadgeModifier: ViewModifier {
    let label: String?
    let alignment: Alignment

    func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            if let label {
                EnvironmentBadge(label)
                    .padding(Spacing.sm)
                    .allowsHitTesting(false)
            }
        }
    }
}

public extension View {
    /// Overlays an ``EnvironmentBadge`` in the given corner when `label` is
    /// non-nil. Pass `nil` (e.g. for production) to render nothing.
    func environmentBadge(
        _ label: String?,
        alignment: Alignment = .topTrailing
    ) -> some View {
        modifier(EnvironmentBadgeModifier(label: label, alignment: alignment))
    }
}

#Preview("Light") {
    Color.kaso.surfacePrimary
        .ignoresSafeArea()
        .environmentBadge("DEV")
}

#Preview("Dark") {
    Color.kaso.surfacePrimary
        .ignoresSafeArea()
        .environmentBadge("DEV")
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    Color.kaso.surfacePrimary
        .ignoresSafeArea()
        .environmentBadge("DEV")
        .environment(\.dynamicTypeSize, .accessibility1)
}
