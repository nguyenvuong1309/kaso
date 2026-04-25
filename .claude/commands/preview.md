---
description: Hướng dẫn check SwiftUI Preview cho view — multi-state, multi-device, dark mode
argument-hint: <ViewName>
---

Audit và improve `#Preview` cho view **$1**.

## Standard preview structure

Mọi component trong Kaso phải có preview cho:

1. **Default state** — light mode, regular Dynamic Type
2. **Dark mode** — `.preferredColorScheme(.dark)`
3. **Dynamic Type XL** — `.environment(\.dynamicTypeSize, .accessibility5)`
4. **Loading state** (nếu có)
5. **Error state** (nếu có)
6. **Empty state** (nếu có)
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

## Quy trình audit

1. Đọc file `$1View.swift`
2. Đếm số `#Preview` hiện có
3. Liệt kê state nào còn thiếu
4. Đề xuất mock data cho state phức tạp (`previewValue` trong dependency)
5. Tạo preview file riêng nếu nhiều preview: `$1Previews.swift`

## Cấm

- KHÔNG dùng `PreviewProvider` cũ — dùng `#Preview` macro
- KHÔNG hardcode mock data inline — đặt trong `PreviewMocks.swift`
- KHÔNG bỏ qua dark mode preview
