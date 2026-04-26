---
description: Scaffold a new Metal shader with SwiftUI binding (.colorEffect / .layerEffect / MTKView)
argument-hint: <ShaderName> [type: color|distortion|layer|view]
---

Create a new Metal shader: **$1**, type **${2:-color}**.

## Layout

Create files:
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

## Template by Type

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

### `view` — `MTKView` for complex cases

- Create `$1Renderer.swift` implementing `MTKViewDelegate`
- Wrap with `UIViewRepresentable`
- Vertex + Fragment shader pair in `.metal`

## Snapshot Test (Required)

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

## Rules

- DocC comment on the shader function: input/output, performance note
- Test at least 3 states: t=0, t=0.5, t=1.0
- Compile shader with `xcrun metal -c` to verify before committing
- Performance target: 120fps on iPhone 15 Pro, 60fps on iPhone 12

## Checks Before Reporting Done

- [ ] Shader compile clean
- [ ] Modifier has `#Preview`
- [ ] Snapshot test pass
- [ ] DocC comments are complete
- [ ] Tested in Reduce Motion mode (reasonable fallback)
