import BudgetFlowDomain
import CoreGraphics
import Foundation

struct BudgetFlowRibbon: Identifiable, Equatable {
    let id: String
    let labelKey: String
    let amount: Decimal
    let ratio: Double
    let colorName: String
    let symbolName: String

    let sourceCenterY: CGFloat
    let targetCenterY: CGFloat
    let sourceHalfHeight: CGFloat
    let targetHalfHeight: CGFloat

    let targetTopY: CGFloat
    let targetBottomY: CGFloat
}

struct BudgetFlowLayout: Equatable {
    let canvasSize: CGSize
    let sourceRect: CGRect
    let ribbons: [BudgetFlowRibbon]
    let unallocated: Decimal

    static let empty = BudgetFlowLayout(
        canvasSize: .zero,
        sourceRect: .zero,
        ribbons: [],
        unallocated: 0
    )
}

enum BudgetFlowLayoutBuilder {
    static let sourceColumnWidth: CGFloat = 18
    static let topPadding: CGFloat = 12
    static let bottomPadding: CGFloat = 12
    static let minRibbonHalfHeight: CGFloat = 3
    static let nodeGap: CGFloat = 6

    static func build(flow: BudgetFlow, canvas size: CGSize) -> BudgetFlowLayout {
        guard size.width > 0, size.height > 0, flow.nodes.isEmpty == false else {
            return .empty
        }

        let availableHeight = max(size.height - topPadding - bottomPadding, 0)
        let nodeCount = flow.nodes.count
        let totalGap = CGFloat(max(nodeCount - 1, 0)) * nodeGap
        let usableHeight = max(availableHeight - totalGap, 0)

        let ratios = flow.nodes.map { $0.ratio }
        let ratioSum = ratios.reduce(0, +)
        let normalizedRatios: [Double] = ratioSum > 0
            ? ratios.map { $0 / ratioSum }
            : Array(repeating: 1.0 / Double(nodeCount), count: nodeCount)

        let rawTargetHeights = normalizedRatios.map { CGFloat($0) * usableHeight }
        let targetHeights = rawTargetHeights.map { max($0, minRibbonHalfHeight * 2) }

        let scaleFactor: CGFloat = {
            let sum = targetHeights.reduce(0, +)
            return sum > 0 ? min(usableHeight / sum, 1) : 1
        }()
        let scaledTargetHeights = targetHeights.map { $0 * scaleFactor }

        let sourceHeights = normalizedRatios.map { CGFloat($0) * availableHeight }

        let sourceRect = CGRect(
            x: 0,
            y: topPadding,
            width: sourceColumnWidth,
            height: availableHeight
        )

        var ribbons: [BudgetFlowRibbon] = []
        var sourceCursor: CGFloat = sourceRect.minY
        var targetCursor: CGFloat = topPadding

        for index in flow.nodes.indices {
            let node = flow.nodes[index]
            let sourceHeight = sourceHeights[index]
            let targetHeight = scaledTargetHeights[index]

            let sourceCenter = sourceCursor + sourceHeight / 2
            let targetTop = targetCursor
            let targetBottom = targetCursor + targetHeight
            let targetCenter = targetTop + targetHeight / 2

            ribbons.append(
                BudgetFlowRibbon(
                    id: node.id,
                    labelKey: node.labelKey,
                    amount: node.amount,
                    ratio: node.ratio,
                    colorName: node.colorName,
                    symbolName: node.symbolName,
                    sourceCenterY: sourceCenter,
                    targetCenterY: targetCenter,
                    sourceHalfHeight: max(sourceHeight / 2, minRibbonHalfHeight),
                    targetHalfHeight: max(targetHeight / 2, minRibbonHalfHeight),
                    targetTopY: targetTop,
                    targetBottomY: targetBottom
                )
            )

            sourceCursor += sourceHeight
            targetCursor += targetHeight + nodeGap
        }

        return BudgetFlowLayout(
            canvasSize: size,
            sourceRect: sourceRect,
            ribbons: ribbons,
            unallocated: flow.unallocated
        )
    }
}
