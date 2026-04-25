---
description: Scaffold Metal shader mới với SwiftUI binding (.colorEffect / .layerEffect / MTKView)
argument-hint: <ShaderName> [type: color|distortion|layer|view]
---

Tạo Metal shader mới: **$1**, type **${2:-color}**.

## Layout

Tạo files:
```
Packages/DesignSystem/KasoMetalEffects/
├── Sources/KasoMetalEffects/
│   ├── Shaders/
│   │   └── $1.metal
│   └── Modifiers/
│       └── $1Modifier.swift
└── Tests/KasoMetalEffectsTests/
    └── $1SnapshotTests.swift
```

## Template theo type

### `color` — `.colorEffect` modifier

```metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 $1(float2 position, half4 currentColor, float time) {
    // TODO: implement
    return currentColor;
}
```

```swift
import SwiftUI

public extension View {
    func $1Effect(time: TimeInterval) -> some View {
        colorEffect(ShaderLibrary.$1(.float(time)))
    }
}
```

### `distortion` — `.distortionEffect`

```metal
[[ stitchable ]] float2 $1(float2 position, float time) {
    return position + sin(position.y * 0.1 + time) * 5.0;
}
```

### `layer` — `.layerEffect`

```metal
[[ stitchable ]] half4 $1(float2 position, SwiftUI::Layer layer, float time) {
    return layer.sample(position);
}
```

### `view` — `MTKView` cho case phức tạp

- Tạo `$1Renderer.swift` implement `MTKViewDelegate`
- Wrap bằng `UIViewRepresentable`
- Vertex + Fragment shader pair trong `.metal`

## Snapshot test (bắt buộc)

```swift
import SnapshotTesting
import Testing
@testable import KasoMetalEffects

@Test("$1 renders correctly at default state")
func $1Default() throws {
    let view = SampleView().$1Effect(time: 0)
        .frame(width: 300, height: 200)
    assertSnapshot(of: view, as: .image)
}
```

## Quy tắc

- DocC comment trên shader function: input/output, performance note
- Test ít nhất 3 state: t=0, t=0.5, t=1.0
- Compile shader bằng `xcrun metal -c` để verify trước khi commit
- Performance target: 120fps trên iPhone 15 Pro, 60fps trên iPhone 12

## Kiểm tra trước khi báo done

- [ ] Shader compile clean
- [ ] Modifier có `#Preview`
- [ ] Snapshot test pass
- [ ] DocC comment đầy đủ
- [ ] Đã thử trên Reduce Motion mode (fallback hợp lý)
