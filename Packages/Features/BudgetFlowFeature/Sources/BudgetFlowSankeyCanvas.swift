import BudgetFlowDomain
import KasoDesignSystem
import SwiftUI

struct BudgetFlowSankeyCanvas: View {
    let flow: BudgetFlow
    let displayMode: BudgetFlowDisplayMode
    let selectedNodeID: String?
    let onTap: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = BudgetFlowLayoutBuilder.build(flow: flow, canvas: ribbonCanvasSize(in: size))
            HStack(spacing: Spacing.md) {
                BudgetFlowSourceColumn(
                    layout: layout,
                    accent: Color.kaso.accent
                )
                .frame(width: BudgetFlowLayoutBuilder.sourceColumnWidth)

                BudgetFlowRibbonLayer(
                    layout: layout,
                    selectedNodeID: selectedNodeID,
                    onTap: onTap
                )
                .frame(maxWidth: .infinity)

                BudgetFlowLegendColumn(
                    flow: flow,
                    layout: layout,
                    displayMode: displayMode,
                    selectedNodeID: selectedNodeID,
                    onTap: onTap
                )
                .frame(width: legendWidth(for: size))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedNodeID != nil {
                    onClear()
                }
            }
        }
        .frame(height: 280)
    }

    private func ribbonCanvasSize(in size: CGSize) -> CGSize {
        let legend = legendWidth(for: size)
        let width = max(size.width - BudgetFlowLayoutBuilder.sourceColumnWidth - legend - Spacing.md * 2, 0)
        return CGSize(width: width, height: size.height)
    }

    private func legendWidth(for size: CGSize) -> CGFloat {
        min(max(size.width * 0.42, 140), 200)
    }
}

private struct BudgetFlowSourceColumn: View {
    let layout: BudgetFlowLayout
    let accent: Color

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(accent.opacity(0.85))
                .frame(width: BudgetFlowLayoutBuilder.sourceColumnWidth, height: layout.sourceRect.height)
                .offset(y: layout.sourceRect.minY)
        }
        .frame(height: layout.canvasSize.height, alignment: .top)
    }
}

private struct BudgetFlowRibbonLayer: View {
    let layout: BudgetFlowLayout
    let selectedNodeID: String?
    let onTap: (String) -> Void

    var body: some View {
        ZStack {
            ForEach(layout.ribbons) { ribbon in
                BudgetFlowRibbonShape(
                    ribbon: ribbon,
                    canvasSize: layout.canvasSize,
                    isDimmed: selectedNodeID != nil && selectedNodeID != ribbon.id,
                    onTap: { onTap(ribbon.id) }
                )
            }
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .topLeading)
        .clipped()
    }
}

private struct BudgetFlowRibbonShape: View {
    let ribbon: BudgetFlowRibbon
    let canvasSize: CGSize
    let isDimmed: Bool
    let onTap: () -> Void

    var body: some View {
        let baseColor = Color.kaso.category(named: ribbon.colorName)
        Rectangle()
            .fill(.clear)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .colorEffect(
                ShaderLibrary.bundle(.module).budget_flow_ribbon(
                    .float(Float(ribbon.sourceCenterY)),
                    .float(Float(ribbon.targetCenterY)),
                    .float(Float(ribbon.sourceHalfHeight)),
                    .float(Float(ribbon.targetHalfHeight)),
                    .float(Float(canvasSize.width)),
                    .float(isDimmed ? 0.25 : 1.0),
                    .color(baseColor)
                )
            )
            .contentShape(BudgetFlowRibbonHitArea(ribbon: ribbon, canvasSize: canvasSize))
            .onTapGesture { onTap() }
            .accessibilityElement()
            .accessibilityLabel(Text(LocalizedStringKey(ribbon.labelKey), bundle: .module))
            .accessibilityValue(Text(BudgetFlowFormatters.percent(ribbon.ratio)))
            .accessibilityAddTraits(.isButton)
    }
}

private struct BudgetFlowRibbonHitArea: Shape {
    let ribbon: BudgetFlowRibbon
    let canvasSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let p0 = CGPoint(x: 0, y: ribbon.sourceCenterY)
        let p3 = CGPoint(x: canvasSize.width, y: ribbon.targetCenterY)
        let c1 = CGPoint(x: canvasSize.width * 0.45, y: ribbon.sourceCenterY)
        let c2 = CGPoint(x: canvasSize.width * 0.55, y: ribbon.targetCenterY)

        path.move(to: CGPoint(x: p0.x, y: p0.y - ribbon.sourceHalfHeight))
        path.addCurve(
            to: CGPoint(x: p3.x, y: p3.y - ribbon.targetHalfHeight),
            control1: CGPoint(x: c1.x, y: c1.y - ribbon.sourceHalfHeight),
            control2: CGPoint(x: c2.x, y: c2.y - ribbon.targetHalfHeight)
        )
        path.addLine(to: CGPoint(x: p3.x, y: p3.y + ribbon.targetHalfHeight))
        path.addCurve(
            to: CGPoint(x: p0.x, y: p0.y + ribbon.sourceHalfHeight),
            control1: CGPoint(x: c2.x, y: c2.y + ribbon.targetHalfHeight),
            control2: CGPoint(x: c1.x, y: c1.y + ribbon.sourceHalfHeight)
        )
        path.closeSubpath()
        return path
    }
}

private struct BudgetFlowLegendColumn: View {
    let flow: BudgetFlow
    let layout: BudgetFlowLayout
    let displayMode: BudgetFlowDisplayMode
    let selectedNodeID: String?
    let onTap: (String) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.ribbons) { ribbon in
                BudgetFlowLegendChip(
                    ribbon: ribbon,
                    currencyCode: flow.currencyCode,
                    displayMode: displayMode,
                    isSelected: selectedNodeID == ribbon.id,
                    isDimmed: selectedNodeID != nil && selectedNodeID != ribbon.id,
                    onTap: { onTap(ribbon.id) }
                )
                .offset(y: max(ribbon.targetTopY - 2, 0))
            }
        }
        .frame(height: layout.canvasSize.height, alignment: .topLeading)
    }
}

private struct BudgetFlowLegendChip: View {
    let ribbon: BudgetFlowRibbon
    let currencyCode: String
    let displayMode: BudgetFlowDisplayMode
    let isSelected: Bool
    let isDimmed: Bool
    let onTap: () -> Void

    var body: some View {
        let accent = Color.kaso.category(named: ribbon.colorName)
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: ribbon.symbolName)
                    .font(.kaso.caption)
                    .foregroundStyle(accent)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(ribbon.labelKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textPrimary)
                        .lineLimit(1)

                    Text(value)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.18) : Color.clear)
            )
            .opacity(isDimmed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(Text(LocalizedStringKey(ribbon.labelKey), bundle: .module))
        .accessibilityValue(Text(value))
    }

    private var value: String {
        switch displayMode {
        case .amount:
            BudgetFlowFormatters.amount(ribbon.amount, currencyCode: currencyCode)
        case .percent:
            BudgetFlowFormatters.percent(ribbon.ratio)
        }
    }
}
