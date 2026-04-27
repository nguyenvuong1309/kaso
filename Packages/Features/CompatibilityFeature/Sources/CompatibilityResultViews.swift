import SwiftUI
import CompatibilityDomain
import KasoDesignSystem

struct CompatibilityResultView: View {
    let result: CompatibilityResult
    let onRestartTapped: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            CompatibilityScoreCard(result: result)
            DimensionRadarCard(result: result)
            ConflictInsightList(conflicts: result.highlightedConflicts)
            ConversationStarterCards(starters: result.conversationStarters)
            CompatibilityShareActions(
                result: result,
                onRestartTapped: onRestartTapped
            )
        }
    }
}

private struct CompatibilityScoreCard: View {
    let result: CompatibilityResult

    var body: some View {
        KasoCard {
            VStack(spacing: Spacing.md) {
                CompatibilityScoreRing(
                    score: result.overallScore,
                    colorName: result.compatibilityType.colorName
                )

                VStack(spacing: Spacing.xs) {
                    Text(LocalizedStringKey(result.compatibilityType.titleKey), bundle: .module)
                        .font(.kaso.titleLarge)
                        .foregroundStyle(Color.kaso.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(LocalizedStringKey(result.compatibilityType.descriptionKey), bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct CompatibilityScoreRing: View {
    let score: Double
    let colorName: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedScore = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.kaso.surfacePrimary, lineWidth: Layout.ringWidth)
            Circle()
                .trim(from: 0, to: max(0, min(displayedScore / 100, 1)))
                .stroke(
                    Color.kaso.category(named: colorName),
                    style: StrokeStyle(
                        lineWidth: Layout.ringWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: Spacing.xs) {
                Text(displayedScore.formatted(.number.precision(.fractionLength(0))))
                    .font(.kaso.numericLarge)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text("compatibility.result.score", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
        .frame(width: Layout.ringSize, height: Layout.ringSize)
        .onAppear {
            displayedScore = reduceMotion ? score : 0
            guard reduceMotion == false else {
                return
            }
            withAnimation(.linear(duration: 1.2)) {
                displayedScore = score
            }
        }
        .accessibilityLabel(Text("compatibility.result.score", bundle: .module))
        .accessibilityValue(Text(score.formatted(.number.precision(.fractionLength(0)))))
    }
}

private struct DimensionRadarCard: View {
    let result: CompatibilityResult

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("compatibility.dimension.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                DimensionRadarChart(scores: result.dimensionScores)
                    .frame(height: Layout.chartHeight)
                    .accessibilityHidden(true)

                ForEach(CompatibilityDimension.allCases) { dimension in
                    DimensionScoreRow(
                        dimension: dimension,
                        score: result.dimensionScores[dimension] ?? 0
                    )
                }
            }
        }
    }
}

private struct DimensionRadarChart: View {
    let scores: [CompatibilityDimension: Double]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.42

            for ring in 1...4 {
                let path = polygonPath(
                    center: center,
                    radius: radius * CGFloat(ring) / 4,
                    values: Array(repeating: 1, count: CompatibilityDimension.allCases.count)
                )
                context.stroke(path, with: .color(Color.kaso.surfaceSecondary), lineWidth: 1)
            }

            let values = CompatibilityDimension.allCases.map {
                max(0, min((scores[$0] ?? 0) / 100, 1))
            }
            let scorePath = polygonPath(
                center: center,
                radius: radius,
                values: values
            )
            context.fill(scorePath, with: .color(Color.kaso.accent.opacity(0.22)))
            context.stroke(scorePath, with: .color(Color.kaso.accent), lineWidth: 2)
        }
    }

    private func polygonPath(
        center: CGPoint,
        radius: CGFloat,
        values: [Double]
    ) -> Path {
        var path = Path()
        for index in values.indices {
            let angle = -CGFloat.pi / 2 + 2 * CGFloat.pi * CGFloat(index) / CGFloat(values.count)
            let valueRadius = radius * CGFloat(values[index])
            let point = CGPoint(
                x: center.x + cos(angle) * valueRadius,
                y: center.y + sin(angle) * valueRadius
            )
            index == values.startIndex ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct DimensionScoreRow: View {
    let dimension: CompatibilityDimension
    let score: Double

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Label {
                    Text(LocalizedStringKey(dimension.titleKey), bundle: .module)
                } icon: {
                    Image(systemName: dimension.symbolName)
                        .foregroundStyle(Color.kaso.category(named: dimension.colorName))
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textPrimary)

                Spacer(minLength: Spacing.md)

                Text(score.formatted(.number.precision(.fractionLength(0))))
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.kaso.surfacePrimary)
                    Capsule()
                        .fill(Color.kaso.category(named: dimension.colorName))
                        .frame(width: proxy.size.width * max(0, min(score / 100, 1)))
                }
            }
            .frame(height: Layout.progressHeight)
        }
    }
}

private struct ConflictInsightList: View {
    let conflicts: [ConflictInsight]
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("compatibility.conflict.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                if conflicts.isEmpty {
                    Text("compatibility.conflict.empty", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                } else {
                    ForEach(conflicts) { conflict in
                        DisclosureGroup(
                            isExpanded: expandedBinding(for: conflict)
                        ) {
                            Text(LocalizedStringKey(conflict.descriptionKey), bundle: .module)
                                .font(.kaso.body)
                                .foregroundStyle(Color.kaso.textSecondary)
                        } label: {
                            Text(LocalizedStringKey(conflict.titleKey), bundle: .module)
                                .font(.kaso.body)
                                .foregroundStyle(Color.kaso.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func expandedBinding(for conflict: ConflictInsight) -> Binding<Bool> {
        Binding(
            get: { expandedIDs.contains(conflict.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedIDs.insert(conflict.id)
                } else {
                    expandedIDs.remove(conflict.id)
                }
            }
        )
    }
}

private struct ConversationStarterCards: View {
    let starters: [String]

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("compatibility.starter.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(starters, id: \.self) { starter in
                            Text(LocalizedStringKey(starter), bundle: .module)
                                .font(.kaso.body)
                                .foregroundStyle(Color.kaso.textPrimary)
                                .padding(Spacing.md)
                                .frame(width: Layout.starterWidth, alignment: .leading)
                                .background(
                                    Color.kaso.surfacePrimary,
                                    in: RoundedRectangle(
                                        cornerRadius: Radius.lg,
                                        style: .continuous
                                    )
                                )
                        }
                    }
                }
            }
        }
    }
}

private struct CompatibilityShareActions: View {
    let result: CompatibilityResult
    let onRestartTapped: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ShareLink(
                item: CompatibilityShareTransferable(result: result),
                preview: SharePreview("Kaso Compatibility")
            ) {
                Label {
                    Text("compatibility.share.button", bundle: .module)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                onRestartTapped()
            } label: {
                Label {
                    Text("compatibility.restart", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .font(.kaso.body)
    }
}

private enum Layout {
    static let chartHeight: CGFloat = 220
    static let progressHeight: CGFloat = 8
    static let ringSize: CGFloat = 164
    static let ringWidth: CGFloat = 14
    static let starterWidth: CGFloat = 240
}
