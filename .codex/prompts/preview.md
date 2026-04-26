---
description: Audit + improve SwiftUI Preview for a view — multi-state, multi-device, dark mode.
---

Audit `#Preview` for the view named in the argument. Ensure sufficient coverage:

## Standard preview matrix

Every component must have previews for:

1. **Default** (light, regular Dynamic Type)
2. **Dark mode** — `.preferredColorScheme(.dark)`
3. **Dynamic Type XL** — `.environment(\.dynamicTypeSize, .accessibility5)`
4. **Loading state** (if any)
5. **Error state** (if any)
6. **Empty state** (if any)
7. **Multi-device**: iPhone SE + iPhone 16 Pro Max + iPad

## Template

```swift
#Preview("Light", traits: .sizeThatFitsLayout) {
    ${VIEW_NAME}(store: Store(initialState: .init()) { ${VIEW_NAME%View}Feature() })
        .padding()
}

#Preview("Dark", traits: .sizeThatFitsLayout) {
    ${VIEW_NAME}(store: Store(initialState: .init()) { ${VIEW_NAME%View}Feature() })
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL", traits: .sizeThatFitsLayout) {
    ${VIEW_NAME}(store: Store(initialState: .init()) { ${VIEW_NAME%View}Feature() })
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Loading") { /* ... */ }
#Preview("Empty") { /* ... */ }
#Preview("Error") { /* ... */ }
#Preview("iPhone SE", traits: .fixedLayout(width: 320, height: 568)) { /* ... */ }
```

## Steps

1. Read file `${VIEW_NAME}.swift`
2. Count existing `#Preview` blocks
3. List missing states
4. Propose mock data for complex states (`previewValue` in dependencies)
5. Create a separate preview file if there are many: `${VIEW_NAME}Previews.swift`

## Forbidden

- Do not use old `PreviewProvider` — use the `#Preview` macro
- Do not hardcode mock data inline — place it in `PreviewMocks.swift`
- Do not skip dark mode preview
