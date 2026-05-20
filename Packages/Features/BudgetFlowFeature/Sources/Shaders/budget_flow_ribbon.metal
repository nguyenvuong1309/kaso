#include <metal_stdlib>
using namespace metal;

/// Trace a cubic Bézier curve and shade pixels that fall within a thickness band
/// whose half-height interpolates linearly from `startHalfHeight` to `endHalfHeight`.
///
/// Inputs (passed via SwiftUI `.colorEffect`):
/// - position: pixel position in layer space (auto)
/// - color: existing pixel color, discarded (auto)
/// - startY, endY: vertical coordinates of curve endpoints
/// - startHalfHeight, endHalfHeight: half thickness at the two endpoints
/// - canvasWidth: width of the layer (used for control points)
/// - selectedAlpha: dim factor for non-selected ribbons (1 = full opacity)
/// - baseColor: ribbon color (premultiplied half4 from SwiftUI)
inline float2 cubic_bezier(float2 p0, float2 p1, float2 p2, float2 p3, float t) {
    float u = 1.0 - t;
    return u * u * u * p0
        + 3.0 * u * u * t * p1
        + 3.0 * u * t * t * p2
        + t * t * t * p3;
}

[[ stitchable ]] half4 budget_flow_ribbon(
    float2 position,
    half4 color,
    float startY,
    float endY,
    float startHalfHeight,
    float endHalfHeight,
    float canvasWidth,
    float selectedAlpha,
    half4 baseColor
) {
    const int N = 56;
    float2 p0 = float2(0.0, startY);
    float2 p1 = float2(canvasWidth * 0.45, startY);
    float2 p2 = float2(canvasWidth * 0.55, endY);
    float2 p3 = float2(canvasWidth, endY);

    float minDist = 1e9;
    float bestT = 0.0;
    for (int i = 0; i <= N; ++i) {
        float t = float(i) / float(N);
        float2 q = cubic_bezier(p0, p1, p2, p3, t);
        float d = distance(position, q);
        if (d < minDist) {
            minDist = d;
            bestT = t;
        }
    }

    float halfHeight = mix(startHalfHeight, endHalfHeight, bestT);
    if (minDist > halfHeight + 2.0) {
        return half4(0.0);
    }

    float feather = 1.25;
    float inner = max(halfHeight - feather, 0.0);
    float edge = 1.0 - smoothstep(inner, halfHeight + feather, minDist);

    float centerness = 1.0 - clamp(minDist / max(halfHeight, 1.0), 0.0, 1.0);
    float gradient = mix(0.55, 1.0, pow(centerness, 0.65));

    half3 rgb = baseColor.rgb * half(gradient);
    half alpha = baseColor.a * half(edge) * half(selectedAlpha);
    return half4(rgb * alpha, alpha);
}
