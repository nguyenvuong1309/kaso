---
description: Audit + improve SwiftUI Preview cho view — multi-state, multi-device, dark mode.
---

Audit `#Preview` cho view tên trong argument. Đảm bảo coverage đủ:

## Standard preview matrix

Mọi component phải có preview cho:

1. **Default** (light, regular Dynamic Type)
2. **Dark mode** — `.preferredColorScheme(.dark)`
3. **Dynamic Type XL** — `.environment(\.dynamicTypeSize, .accessibility5)`
4. **Loading state** (nếu có)
5. **Error state** (nếu có)
6. **Empty state** (nếu có)
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

## Bước

1. Đọc file `${VIEW_NAME}.swift`
2. Đếm `#Preview` hiện có
3. Liệt kê state thiếu
4. Đề xuất mock data cho state phức tạp (`previewValue` trong dependency)
5. Tạo preview file riêng nếu nhiều: `${VIEW_NAME}Previews.swift`

## Cấm

- KHÔNG dùng `PreviewProvider` cũ — dùng `#Preview` macro
- KHÔNG hardcode mock inline — đặt trong `PreviewMocks.swift`
- KHÔNG bỏ qua dark mode preview
