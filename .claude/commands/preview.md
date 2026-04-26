---
description: Guide for checking SwiftUI Preview for a view — multi-state, multi-device, dark mode
argument-hint: <ViewName>
---

Audit and improve `#Preview` for view **$1**.

## Standard preview structure

Every Kaso component must have previews for:

1. **Default state** — light mode, regular Dynamic Type
2. **Dark mode** — `.preferredColorScheme(.dark)`
3. **Dynamic Type XL** — `.environment(\.dynamicTypeSize, .accessibility5)`
4. **Loading state** (if any)
5. **Error state** (if any)
6. **Empty state** (if any)
7. **Multi-device**: iPhone SE (compact) + iPhone 16 Pro Max (large) + iPad

## Template

```swift
#Preview("Light", traits: .sizeThatFitsLayout) {
    $1View(store: Store(initialState: .init()) { $1Feature() })
        .padding()
}

#Preview("Dark", traits: .sizeThatFitsLayout) {
    $1View(store: Store(initialState: .init()) { $1Feature() })
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL", traits: .sizeThatFitsLayout) {
    $1View(store: Store(initialState: .init()) { $1Feature() })
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Loading") { /* ... */ }
#Preview("Empty") { /* ... */ }
#Preview("Error") { /* ... */ }

#Preview("iPhone SE", traits: .fixedLayout(width: 320, height: 568)) {
    $1View(store: Store(initialState: .init()) { $1Feature() })
}
```

## Audit Flow

1. Read file `$1View.swift`
2. Count existing `#Preview` blocks
3. List missing states
4. Propose mock data for complex states (`previewValue` in dependencies)
5. Create a separate preview file if there are many previews: `$1Previews.swift`

## Forbidden

- Do not use old `PreviewProvider` — use the `#Preview` macro
- Do not hardcode mock data inline — place it in `PreviewMocks.swift`
- Do not skip dark mode preview
