import KasoDesignSystem
import MoneyPersonalityDomain
import SwiftUI

public struct MoneyPersonalityShareCard: View {
    let profile: MoneyPersonalityProfile
    @State private var renderedImage: Image?

    public init(profile: MoneyPersonalityProfile) {
        self.profile = profile
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            shareCardContent
                .frame(width: 320, height: 568)  // 9:16 ratio (scaled)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)

            if let renderedImage {
                ShareLink(
                    item: renderedImage,
                    preview: SharePreview("Kaso · Money Personality", image: renderedImage)
                ) {
                    Label {
                        Text("personality.share.action", bundle: .module)
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.kaso.accent)
            } else {
                ProgressView()
            }
        }
        .padding(Spacing.lg)
        .background(Color.kaso.surfacePrimary)
        .onAppear {
            renderImage()
        }
    }

    @MainActor
    private func renderImage() {
        let renderer = ImageRenderer(content: shareCardContent.frame(width: 1080, height: 1920))
        renderer.scale = 1
        if let cgImage = renderer.cgImage {
            renderedImage = Image(decorative: cgImage, scale: 1.0)
        }
    }

    @ViewBuilder
    private var shareCardContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: profile.type.primaryColorHex),
                    Color(hex: profile.type.secondaryColorHex),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: Spacing.lg) {
                Spacer()

                Text("Kaso")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text(profile.type.emoji)
                    .font(.system(size: 96))

                VStack(spacing: Spacing.sm) {
                    Text("Tôi là")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(LocalizedStringKey(profile.type.nameKey), bundle: .module)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey(profile.type.taglineKey), bundle: .module)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                }

                Spacer()

                if profile.confidence > 0 {
                    Text(String(format: "%.0f%% confidence", profile.confidence * 100))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("kaso.app")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, Spacing.lg)
            }
        }
    }
}

private extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
