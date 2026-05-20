import KasoDesignSystem
import SpendingDNADomain
import SwiftUI

public struct SpendingDNAShareCard: View {
    let report: SpendingDNAReport
    @State private var renderedImage: Image?

    public init(report: SpendingDNAReport) {
        self.report = report
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            shareCardContent
                .frame(width: 320, height: 568)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)

            if let renderedImage {
                ShareLink(
                    item: renderedImage,
                    preview: SharePreview("Kaso Spending DNA", image: renderedImage)
                ) {
                    Label {
                        Text("dna.share.action", bundle: .module)
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
        .onAppear { renderImage() }
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
                    Color(red: 0.05, green: 0.20, blue: 0.45),
                    Color(red: 0.20, green: 0.45, blue: 0.70),
                    Color(red: 0.35, green: 0.75, blue: 0.70),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                Spacer()

                HStack(spacing: 4) {
                    Text("Kaso")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("DNA")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(String(report.year))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text(report.type.emoji)
                    .font(.system(size: 72))

                Text(LocalizedStringKey(report.type.titleKey), bundle: .module)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(LocalizedStringKey(report.type.taglineKey), bundle: .module)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                shareStat(
                    label: "Tỉ lệ tiết kiệm",
                    value: "\(Int(report.savingsRate * 100))%",
                    emphasized: true
                )
                if let top = report.topCategories.first {
                    shareStat(
                        label: "Mê nhất",
                        value: "\(top.categoryID.capitalized) (\(Int(top.percentage * 100))%)"
                    )
                }
                shareStat(
                    label: "Giao dịch lớn nhất",
                    value: report.largestTransaction.formatted(.currency(code: "VND"))
                )

                Spacer()

                Text("kaso.app")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, Spacing.lg)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private func shareStat(label: String, value: String, emphasized: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.system(
                    size: emphasized ? 24 : 18,
                    weight: emphasized ? .bold : .semibold,
                    design: .rounded
                ))
                .foregroundStyle(.white)
        }
    }
}
