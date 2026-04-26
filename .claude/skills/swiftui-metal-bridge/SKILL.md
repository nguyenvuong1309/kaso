---
name: swiftui-metal-bridge
description: How to bridge SwiftUI ↔ Metal for custom effects — colorEffect, distortionEffect, layerEffect, MTKView. Trigger when the user mentions Metal shaders, MSL, .colorEffect, .layerEffect, MTKView, or custom visual effects.
---

# SwiftUI ↔ Metal Bridge for Kaso

Decision tree: choose the right API for each effect.

## Decision tree

```
Need a custom effect?
├── Only change pixel color (gradient, hue shift, glitch) → .colorEffect
├── Need to warp/distort pixel position (wave, ripple, jelly) → .distortionEffect
├── Need to read another layer for composition (blur, displacement) → .layerEffect
├── Need Canvas + custom drawing logic → Canvas + GraphicsContext
└── Need stateful rendering (60K+ data, particles, real-time simulation) → MTKView
```

## 1. `.colorEffect` — simplest

**Use case**: gradient mesh, noise, hue shift, animated color.

```metal
// File: Shaders/AnimatedGradient.metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 animatedGradient(float2 position, half4 currentColor, float time, float2 size) {
    float2 uv = position / size;
    half3 color = half3(
        sin(uv.x * 3.0 + time) * 0.5 + 0.5,
        cos(uv.y * 3.0 + time * 1.2) * 0.5 + 0.5,
        sin((uv.x + uv.y) * 2.0 + time * 0.8) * 0.5 + 0.5
    );
    return half4(color, currentColor.a);
}
```

```swift
import SwiftUI

public struct AnimatedGradient: View {
    private let startDate = Date()

    public var body: some View {
        TimelineView(.animation) { context in
            Color.clear
                .colorEffect(
                    ShaderLibrary.animatedGradient(
                        .float(context.date.timeIntervalSince(startDate)),
                        .float2(.init(width: 300, height: 200))
                    )
                )
        }
    }
}
```

## 2. `.distortionEffect` — warp position

**Use case**: wave on text, jelly button, water ripple.

```metal
[[ stitchable ]] float2 ripple(float2 position, float time, float2 center) {
    float distance = length(position - center);
    float ripple = sin(distance * 0.05 - time * 3.0) * 10.0;
    float2 direction = normalize(position - center);
    return position + direction * ripple * exp(-distance * 0.005);
}
```

```swift
.distortionEffect(
    ShaderLibrary.ripple(
        .float(time),
        .float2(tapLocation)
    ),
    maxSampleOffset: CGSize(width: 20, height: 20)
)
```

**Note**: `maxSampleOffset` must be larger than the maximum distortion, otherwise pixels will be clipped.

## 3. `.layerEffect` — read another layer

**Use case**: variable blur (Dynamic Island), displacement map, color picker on image.

```metal
[[ stitchable ]] half4 variableBlur(float2 position, SwiftUI::Layer layer, float radius) {
    half4 sum = half4(0);
    int samples = 9;
    for (int i = 0; i < samples; i++) {
        for (int j = 0; j < samples; j++) {
            float2 offset = float2(i - samples/2, j - samples/2) * radius / float(samples);
            sum += layer.sample(position + offset);
        }
    }
    return sum / float(samples * samples);
}
```

## 4. `Canvas` + `GraphicsContext`

**Use case**: 2D vector drawing, custom charts (path-based), small particle counts.

```swift
Canvas { context, size in
    let path = Path { p in
        // draw transactions as Bezier curves
    }
    context.stroke(path, with: .linearGradient(...))
}
```

Use `GraphicsContext.drawLayer { layer in ... }` to apply a Metal shader to a subset.

## 5. `MTKView` through `UIViewRepresentable`

**Use case**: large datasets (60K+ points), 1000+ particles/objects, real-time slider simulations.

```swift
import MetalKit
import SwiftUI

public struct MetalCanvas: UIViewRepresentable {
    public let renderer: KasoRenderer

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 120
        view.delegate = renderer
        view.isOpaque = false
        return view
    }

    public func updateUIView(_ uiView: MTKView, context: Context) {
        renderer.updateState(/* SwiftUI state */)
    }
}

@MainActor
public final class KasoRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState

    public init?(device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return nil }
        self.queue = queue
        // Build pipeline...
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        // Encode draw calls...

        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
```

## 6. Performance rules

- **Target FPS**: 120 (ProMotion), fallback 60. Set `preferredFramesPerSecond`.
- **Avoid CPU stalls**: precompute in the background; GPU only renders
- **Buffer reuse**: 3-buffer rotation for `MTLBuffer` to avoid GPU/CPU sync
- **Texture compression**: ASTC for assets, BC7 for macOS
- **Profiling required**: Instruments → Metal System Trace before merging

## 7. Reduce Motion fallback

Every Metal animation must have a fallback when the user enables Reduce Motion:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    if reduceMotion {
        Color.kaso.surfacePrimary  // static fallback
    } else {
        animatedMetalView
    }
}
```

## 8. Test Metal output

Snapshot test rendered output at fixed times:

```swift
@Test func gradientRendersAtT0() {
    let view = AnimatedGradient(time: 0)
        .frame(width: 300, height: 200)
    assertSnapshot(of: view, as: .image(precision: 0.95))
}
```

Use `precision: 0.95` because GPU rendering can have small jitter across devices.

## 9. When NOT to Use Metal

- Simple animations → `withAnimation { }` is enough
- Particle count <50 → SwiftUI `TimelineView` + `Circle` is enough
- Static visuals → PNG asset + `Image` is enough
- Complex 3D → `SceneKit` (still uses Metal backend, but the API is easier)
