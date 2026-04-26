---
description: Scaffold a new Metal shader — color, distortion, layer, or MTKView.
---

Create a new Metal shader. Argument 1 = shader name, argument 2 = type (color|distortion|layer|view), default `color`.

## Layout files

```
Packages/DesignSystem/KasoMetalEffects/
├── Sources/KasoMetalEffects/
│   ├── Shaders/
│   │   └── ${SHADER_NAME}.metal
│   └── Modifiers/
│       └── ${SHADER_NAME}Modifier.swift
└── Tests/KasoMetalEffectsTests/
    └── ${SHADER_NAME}SnapshotTests.swift
```

## Template by Type

### `color` — `.colorEffect`

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 ${SHADER_NAME}(float2 position, half4 currentColor, float time) {
    return currentColor;
}
```

```swift
import SwiftUI

public extension View {
    func ${SHADER_NAME}Effect(time: TimeInterval) -> some View {
        colorEffect(ShaderLibrary.${SHADER_NAME}(.float(time)))
    }
}
```

### `distortion` — `.distortionEffect`

```metal
[[ stitchable ]] float2 ${SHADER_NAME}(float2 position, float time) {
    return position + sin(position.y * 0.1 + time) * 5.0;
}
```

### `layer` — `.layerEffect`

```metal
[[ stitchable ]] half4 ${SHADER_NAME}(float2 position, SwiftUI::Layer layer, float time) {
    return layer.sample(position);
}
```

### `view` — `MTKView`

- Create `${SHADER_NAME}Renderer.swift` implementing `MTKViewDelegate`
- Wrap with `UIViewRepresentable`
- Vertex + Fragment shader pair

## Required Snapshot Test

```swift
import SnapshotTesting
import Testing
@testable import KasoMetalEffects

@Suite("${SHADER_NAME}")
struct ${SHADER_NAME}SnapshotTests {
    @Test("renders at t=0")
    func atZero() {
        let view = SampleView().${SHADER_NAME}Effect(time: 0)
            .frame(width: 300, height: 200)
        assertSnapshot(of: view, as: .image(precision: 0.95))
    }

    @Test("renders at t=0.5")
    func atHalf() { /* ... */ }

    @Test("renders at t=1.0")
    func atOne() { /* ... */ }
}
```

## Rules

- DocC comment on the shader: input/output, performance note
- Test at least 3 states (t=0, 0.5, 1.0)
- Compile shader: `xcrun -sdk iphoneos metal -c Shader.metal -o /dev/null`
- Performance target: 120fps on iPhone 15 Pro, 60fps on iPhone 12
- Reduce Motion fallback is required

## Checklist Before Reporting Done

- [ ] Shader compile clean
- [ ] Modifier has `#Preview`
- [ ] 3 snapshot test pass
- [ ] DocC comments are complete
- [ ] Reduce Motion fallback exists

## When Metal Is Not Needed

If the effect is simple, suggest native SwiftUI first:
- Simple animation → `withAnimation`
- Particle <50 → `TimelineView` + `Circle`
- Static visual → asset PNG
