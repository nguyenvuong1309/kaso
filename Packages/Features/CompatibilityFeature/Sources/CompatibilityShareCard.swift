import CoreGraphics
import CoreTransferable
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import CompatibilityDomain
import KasoDesignSystem

struct CompatibilityShareTransferable: Transferable {
    let result: CompatibilityResult

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            try await MainActor.run {
                try CompatibilityShareRenderer.render(item.result)
            }
        }
    }
}

private enum CompatibilityShareRenderer {
    @MainActor
    static func render(_ result: CompatibilityResult) throws -> Data {
        let renderer = ImageRenderer(content: CompatibilityShareCard(result: result))
        renderer.proposedSize = ProposedViewSize(Layout.storySize)
        renderer.scale = Layout.scale

        guard let image = renderer.cgImage else {
            throw CompatibilityShareRenderingError.imageRenderingFailed
        }

        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            throw CompatibilityShareRenderingError.imageEncodingFailed
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CompatibilityShareRenderingError.imageEncodingFailed
        }
        return data as Data
    }
}

private enum CompatibilityShareRenderingError: Error {
    case imageRenderingFailed
    case imageEncodingFailed
}

struct CompatibilityShareCard: View {
    let result: CompatibilityResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Kaso")
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer(minLength: Spacing.md)
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.kaso.accent)
            }

            Spacer(minLength: Spacing.md)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("compatibility.share.kicker", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)

                Text(result.overallScore.formatted(.number.precision(.fractionLength(0))))
                    .font(.kaso.numericLarge)
                    .scaleEffect(Layout.scoreScale, anchor: .leading)
                    .padding(.vertical, Spacing.md)
                    .foregroundStyle(Color.kaso.category(named: result.compatibilityType.colorName))

                Text(LocalizedStringKey(result.compatibilityType.titleKey), bundle: .module)
                    .font(.kaso.titleLarge)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(CompatibilityDimension.allCases.prefix(Layout.dimensionLimit)) { dimension in
                    ShareDimensionRow(
                        dimension: dimension,
                        score: result.dimensionScores[dimension] ?? 0
                    )
                }
            }

            Spacer(minLength: Spacing.md)

            Text("compatibility.share.footer", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .padding(Spacing.xl)
        .frame(width: Layout.storySize.width, height: Layout.storySize.height)
        .background(
            LinearGradient(
                colors: [
                    Color.kaso.category(named: result.compatibilityType.colorName).opacity(0.22),
                    Color.kaso.surfacePrimary,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct ShareDimensionRow: View {
    let dimension: CompatibilityDimension
    let score: Double

    var body: some View {
        HStack {
            Label {
                Text(LocalizedStringKey(dimension.titleKey), bundle: .module)
            } icon: {
                Image(systemName: dimension.symbolName)
            }
            .font(.kaso.body)

            Spacer(minLength: Spacing.md)

            Text(score.formatted(.number.precision(.fractionLength(0))))
                .font(.kaso.numericMedium)
        }
        .foregroundStyle(Color.kaso.textPrimary)
    }
}

private enum Layout {
    static let storySize = CGSize(width: 360, height: 640)
    static let scale: CGFloat = 3
    static let scoreScale: CGFloat = 2.8
    static let dimensionLimit = 6
}
