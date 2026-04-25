---
name: swiftui-metal-bridge
description: Cách bridge SwiftUI ↔ Metal cho hiệu ứng custom — colorEffect, distortionEffect, layerEffect, MTKView. Trigger khi user nói về Metal shader, MSL, .colorEffect, .layerEffect, MTKView, hoặc visual effects custom.
---

# SwiftUI ↔ Metal Bridge cho Kaso

Decision tree: chọn API nào cho hiệu ứng nào.

## Decision tree

```
Cần hiệu ứng custom?
├── Chỉ thay đổi pixel color (gradient, hue shift, glitch) → .colorEffect
├── Cần warp/distort vị trí pixel (wave, ripple, jelly) → .distortionEffect
├── Cần đọc layer khác để compose (blur, displacement) → .layerEffect
├── Cần Canvas + custom drawing logic → Canvas + GraphicsContext
└── Cần stateful render (60K+ data, particle, real-time sim) → MTKView
```

## 1. `.colorEffect` — đơn giản nhất

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

## 2. `.distortionEffect` — warp vị trí

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

**Lưu ý**: `maxSampleOffset` phải lớn hơn distortion tối đa, không thì pixel bị clip.

## 3. `.layerEffect` — đọc layer khác

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

**Use case**: 2D vector drawing, chart custom (path-based), particle nhỏ.

```swift
Canvas { context, size in
    let path = Path { p in
        // draw transactions as bezier
    }
    context.stroke(path, with: .linearGradient(...))
}
```

`GraphicsContext.drawLayer { layer in ... }` để apply Metal shader cho subset.

## 5. `MTKView` qua `UIViewRepresentable`

**Use case**: dữ liệu lớn (60K+ point), particle 1000+ vật thể, real-time slider sim.

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
- **Avoid CPU stall**: precompute trên background, GPU chỉ render
- **Buffer reuse**: 3-buffer rotation cho `MTLBuffer` để tránh GPU/CPU sync
- **Texture compression**: ASTC cho asset, BC7 cho macOS
- **Profiling bắt buộc**: Instruments → Metal System Trace trước khi merge

## 7. Reduce Motion fallback

Mọi animation Metal phải có fallback khi user bật Reduce Motion:

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

Snapshot test render output ở fixed time:

```swift
@Test func gradientRendersAtT0() {
    let view = AnimatedGradient(time: 0)
        .frame(width: 300, height: 200)
    assertSnapshot(of: view, as: .image(precision: 0.95))
}
```

`precision: 0.95` vì GPU render có thể nhỏ jitter giữa device.

## 9. Khi nào KHÔNG dùng Metal

- Animation đơn giản → `withAnimation { }` đủ
- Particle <50 → SwiftUI `TimelineView` + `Circle` đủ
- Static visual → asset PNG + `Image` đủ
- Complex 3D → `SceneKit` (vẫn dùng Metal backend nhưng API dễ hơn)
