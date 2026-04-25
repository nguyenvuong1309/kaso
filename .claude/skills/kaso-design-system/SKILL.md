---
name: kaso-design-system
description: Cách dùng KasoDesignSystem token (color, font, spacing, radius, shadow, motion) và component. Trigger khi viết SwiftUI view mới, sửa style, hoặc khi user nói về design token, color, font, spacing, theme, dark mode.
---

# Kaso Design System

Mọi UI trong Kaso phải dùng token từ `KasoDesignSystem` package.
Hardcode value sẽ bị reject ở review.

## 1. Color tokens

### Semantic colors (recommended)

```swift
import KasoDesignSystem

Color.kaso.surfacePrimary      // background chính
Color.kaso.surfaceSecondary    // background nhẹ hơn
Color.kaso.surfaceTertiary     // card, sheet
Color.kaso.contentPrimary      // text chính
Color.kaso.contentSecondary    // text phụ
Color.kaso.contentTertiary     // hint, placeholder
Color.kaso.brand               // accent màu chủ đạo
Color.kaso.brandMuted          // accent nhạt
Color.kaso.success             // số dương, hoàn thành
Color.kaso.warning             // gần ngân sách
Color.kaso.danger              // vượt ngân sách, error
Color.kaso.info                // notification info
Color.kaso.divider             // line separator
```

### Category colors (cho danh mục giao dịch)

```swift
Color.kaso.category.food       // ăn uống
Color.kaso.category.transport  // đi lại
Color.kaso.category.housing    // nhà ở
Color.kaso.category.entertainment
Color.kaso.category.health
Color.kaso.category.education
Color.kaso.category.shopping
Color.kaso.category.other
```

Tự động adapt light/dark.

### Sai

```swift
.foregroundColor(.black)                    // hardcode
.foregroundColor(Color(hex: "#1A1A1A"))     // hardcode
.background(.white)                          // hardcode
.background(.systemBackground)               // dùng UIColor — sai
```

## 2. Typography

```swift
Font.kaso.displayLarge      // 48pt — Wrapped, hero number
Font.kaso.displayMedium     // 36pt
Font.kaso.titleLarge        // 28pt — screen title
Font.kaso.titleMedium       // 22pt — section header
Font.kaso.titleSmall        // 18pt
Font.kaso.bodyLarge         // 17pt — primary body
Font.kaso.bodyMedium        // 15pt — secondary body
Font.kaso.bodySmall         // 13pt — caption
Font.kaso.labelLarge        // 15pt semibold — button label
Font.kaso.labelMedium       // 13pt medium — chip label
Font.kaso.numericLarge      // 32pt monospaced digit — số tiền chính
Font.kaso.numericMedium     // 22pt monospaced digit
```

Mọi font tự động hỗ trợ Dynamic Type. Số tiền **bắt buộc** dùng `numeric*` cho tabular alignment.

### Sai

```swift
.font(.system(size: 28, weight: .bold))     // không Dynamic Type
.font(.title)                                // không tabular cho số
```

## 3. Spacing (4-pt grid)

```swift
Spacing.xxs   // 2pt
Spacing.xs    // 4pt
Spacing.sm    // 8pt
Spacing.md    // 16pt — default
Spacing.lg    // 24pt
Spacing.xl    // 32pt
Spacing.xxl   // 48pt
Spacing.xxxl  // 64pt
```

```swift
VStack(spacing: Spacing.md) { ... }
.padding(Spacing.lg)
.padding(.horizontal, Spacing.md)
```

KHÔNG dùng số literal: `.padding(16)` → `.padding(Spacing.md)`.

## 4. Radius

```swift
Radius.sm     // 4pt
Radius.md     // 8pt
Radius.lg     // 12pt — card default
Radius.xl     // 16pt
Radius.xxl    // 24pt — sheet
Radius.full   // 9999pt — pill
```

```swift
.clipShape(RoundedRectangle(cornerRadius: Radius.lg))
```

## 5. Shadow

```swift
Shadow.sm     // subtle, hover
Shadow.md     // card resting
Shadow.lg     // elevated card, popover
Shadow.xl     // sheet, modal
```

```swift
.shadow(Shadow.md)
```

## 6. Motion

```swift
Motion.snappy             // .spring(response: 0.3, damping: 0.8) — default
Motion.smooth             // .spring(response: 0.5, damping: 0.85)
Motion.gentle             // .spring(response: 0.7, damping: 0.9)
Motion.bouncy             // .spring(response: 0.4, damping: 0.6)
Motion.duration.fast      // 0.2
Motion.duration.normal    // 0.3
Motion.duration.slow      // 0.5
```

```swift
.animation(Motion.snappy, value: store.isExpanded)
withAnimation(Motion.bouncy) { ... }
```

Tự động fallback sang `.linear(duration: 0.01)` khi `accessibilityReduceMotion`.

## 7. Components

Component có sẵn trong `KasoDesignSystem`:

```swift
KasoButton(.primary, "Lưu") { /* action */ }
KasoButton(.secondary, "Huỷ") { }
KasoButton(.destructive, "Xoá") { }
KasoButton(.ghost, "Bỏ qua") { }

KasoTextField("Số tiền", text: $amount, kind: .currency)
KasoTextField("Ghi chú", text: $note, kind: .multiline)

KasoCard {
    Text("Số dư tháng này")
        .font(.kaso.bodyMedium)
        .foregroundStyle(Color.kaso.contentSecondary)
    Text(amount.formatted(.currency(code: "VND")))
        .font(.kaso.numericLarge)
}

KasoChip("Ăn uống", color: .kaso.category.food, isSelected: true)

KasoEmptyState(
    icon: "tray",
    title: "Chưa có giao dịch",
    message: "Thêm giao dịch đầu tiên của bạn",
    action: ("Thêm", { /* ... */ })
)

KasoLoadingView(message: "Đang tải...")

KasoErrorView(error: error, retry: { /* ... */ })
```

## 8. Modifier helpers

```swift
.kasoCard()                // wrap = KasoCard với padding chuẩn
.kasoSection(title: "...") // section header style
.kasoListRow()             // list row với divider chuẩn
.kasoSheetStyle()          // sheet với drag handle, padding, corner radius
.kasoHaptic(.success)      // trigger haptic chuẩn
```

## 9. Accent customization

User chọn được accent từ palette:

```swift
@Environment(\.kasoAccent) var accent

Color.kaso.brand  // tự động dùng accent user chọn
```

## 10. Quy tắc tổng

| Quy tắc | Ví dụ |
|---------|-------|
| Token > raw value | `Spacing.md` not `16` |
| Semantic > literal color | `Color.kaso.danger` not `.red` |
| Numeric font cho số tiền | `.font(.kaso.numericLarge)` |
| Component có sẵn > tự build | `KasoButton` not `Button` custom |
| Modifier helper khi possible | `.kasoCard()` not stack of modifier |

## 11. Khi cần extend

Nếu thiếu token/component, KHÔNG hardcode tạm thời. Quy trình:

1. Đề xuất bổ sung vào `KasoDesignSystem`
2. Update Figma source of truth
3. Generate token JSON → Swift
4. PR riêng cho design system
5. Mới được dùng ở feature
