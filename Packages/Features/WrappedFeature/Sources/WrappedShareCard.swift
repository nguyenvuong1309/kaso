import KasoDesignSystem
import SwiftUI
import WrappedDomain

public struct WrappedShareCard: View {
    let report: WrappedReport
    @State private var renderedImage: Image?

    public init(report: WrappedReport) {
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
                    preview: SharePreview("Kaso Wrapped", image: renderedImage)
                ) {
                    Label {
                        Text("wrapped.share.action", bundle: .module)
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
                    Color(red: 0.15, green: 0.05, blue: 0.45),
                    Color(red: 0.55, green: 0.15, blue: 0.65),
                    Color(red: 0.9, green: 0.35, blue: 0.45),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                Spacer()

                HStack {
                    Text("Kaso")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Wrapped")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(report.periodLabel)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer()

                Text("✨")
                    .font(.system(size: 64))

                Spacer()

                shareStat(label: "Tổng chi", value: report.totalExpense.formatted(.currency(code: "VND")))
                shareStat(label: "Tổng thu", value: report.totalIncome.formatted(.currency(code: "VND")))
                shareStat(
                    label: "Số dư",
                    value: report.netBalance.formatted(.currency(code: "VND")),
                    emphasized: true
                )

                if let topCategory = report.topCategories.first {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Mê nhất")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(topCategory.categoryID.capitalized)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(Int(topCategory.percentage * 100))% chi tiêu")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    miniStat(value: "\(report.transactionCount)", label: "GD")
                    miniStat(value: "\(report.noSpendDays)", label: "ngày KX")
                    miniStat(value: "\(report.bestStreak)", label: "streak")
                }

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

    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
