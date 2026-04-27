import SwiftUI
import KasoDesignSystem

struct CompatibilityTransitionView: View {
    let onContinueTapped: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            KasoCard {
                VStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.kaso.accent.opacity(0.16))
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(Color.kaso.accent)
                    }
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                    .accessibilityHidden(true)

                    Text("compatibility.partner.title", bundle: .module)
                        .font(.kaso.titleLarge)
                        .foregroundStyle(Color.kaso.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("compatibility.partner.description", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                onContinueTapped()
            } label: {
                Label {
                    Text("compatibility.partner.start", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .font(.kaso.body)
            .accessibilityIdentifier("compatibility.partner.start")
        }
    }
}

private enum Layout {
    static let avatarSize: CGFloat = 96
}
