---
description: Scaffold Metal shader mới — color, distortion, layer, hoặc MTKView.
---

Tạo Metal shader mới. Argument 1 = tên shader, argument 2 = type (color|distortion|layer|view), default `color`.

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

## Template theo type

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

- Tạo `${SHADER_NAME}Renderer.swift` implement `MTKViewDelegate`
- Wrap bằng `UIViewRepresentable`
- Vertex + Fragment shader pair

## Snapshot test bắt buộc

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

## Quy tắc

- DocC comment trên shader: input/output, performance note
- Test ít nhất 3 state (t=0, 0.5, 1.0)
- Compile shader: `xcrun -sdk iphoneos metal -c Shader.metal -o /dev/null`
- Performance target: 120fps trên iPhone 15 Pro, 60fps trên iPhone 12
- Reduce Motion fallback bắt buộc

## Checklist trước khi báo done

- [ ] Shader compile clean
- [ ] Modifier có `#Preview`
- [ ] 3 snapshot test pass
- [ ] DocC comment đầy đủ
- [ ] Reduce Motion fallback có

## Khi không cần Metal

Nếu effect đơn giản, suggest user dùng SwiftUI native trước:
- Animation đơn giản → `withAnimation`
- Particle <50 → `TimelineView` + `Circle`
- Static visual → asset PNG
