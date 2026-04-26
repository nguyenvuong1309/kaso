---
name: kaso-design-system
description: How to use KasoDesignSystem tokens (color, font, spacing, radius, shadow, motion) and components. Trigger when writing new SwiftUI views, editing style, or when the user mentions design tokens, color, font, spacing, theme, or dark mode.
---

# Kaso Design System

Every Kaso UI must use tokens from the `KasoDesignSystem` package.
Hardcoded values will be rejected in review.

## 1. Color tokens

### Semantic colors (recommended)

```swift
import KasoDesignSystem

Color.kaso.surfacePrimary      // main background
Color.kaso.surfaceSecondary    // lighter background
Color.kaso.surfaceTertiary     // card, sheet
Color.kaso.contentPrimary      // primary text
Color.kaso.contentSecondary    // secondary text
Color.kaso.contentTertiary     // hint, placeholder
Color.kaso.brand               // main accent color
Color.kaso.brandMuted          // muted accent
Color.kaso.success             // positive numbers, completed
Color.kaso.warning             // near budget
Color.kaso.danger              // over budget, error
Color.kaso.info                // notification info
Color.kaso.divider             // line separator
```

### Category colors (for transaction categories)

```swift
Color.kaso.category.food       // food
Color.kaso.category.transport  // transport
Color.kaso.category.housing    // housing
Color.kaso.category.entertainment
Color.kaso.category.health
Color.kaso.category.education
Color.kaso.category.shopping
Color.kaso.category.other
```

Automatically adapts to light/dark mode.

### Incorrect

```swift
.foregroundColor(.black)                    // hardcode
.foregroundColor(Color(hex: "#1A1A1A"))     // hardcode
.background(.white)                          // hardcode
.background(.systemBackground)               // uses UIColor — incorrect
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
Font.kaso.numericLarge      // 32pt monospaced digits — primary amount
Font.kaso.numericMedium     // 22pt monospaced digit
```

All fonts automatically support Dynamic Type. Amounts **must** use `numeric*` for tabular alignment.

### Incorrect

```swift
.font(.system(size: 28, weight: .bold))     // no Dynamic Type
.font(.title)                                // no tabular digits for numbers
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

Do not use numeric literals: `.padding(16)` → `.padding(Spacing.md)`.

## 4. Radius

```swift
Radius.sm     // 4pt
Radius.md     // 8pt
Radius.lg     // 12pt — default card
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
Shadow.md     // resting card
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

Automatically falls back to `.linear(duration: 0.01)` when `accessibilityReduceMotion` is enabled.

## 7. Components

Components available in `KasoDesignSystem`:

```swift
KasoButton(.primary, "Save") { /* action */ }
KasoButton(.secondary, "Cancel") { }
KasoButton(.destructive, "Delete") { }
KasoButton(.ghost, "Skip") { }

KasoTextField("Amount", text: $amount, kind: .currency)
KasoTextField("Note", text: $note, kind: .multiline)

KasoCard {
    Text("This month's balance")
        .font(.kaso.bodyMedium)
        .foregroundStyle(Color.kaso.contentSecondary)
    Text(amount.formatted(.currency(code: "VND")))
        .font(.kaso.numericLarge)
}

KasoChip("Food", color: .kaso.category.food, isSelected: true)

KasoEmptyState(
    icon: "tray",
    title: "No transactions yet",
    message: "Add your first transaction",
    action: ("Add", { /* ... */ })
)

KasoLoadingView(message: "Loading...")

KasoErrorView(error: error, retry: { /* ... */ })
```

## 8. Modifier helpers

```swift
.kasoCard()                // wrap = KasoCard with standard padding
.kasoSection(title: "...") // section header style
.kasoListRow()             // list row with standard divider
.kasoSheetStyle()          // sheet with drag handle, padding, corner radius
.kasoHaptic(.success)      // trigger standard haptic
```

## 9. Accent customization

Users can choose an accent from a palette:

```swift
@Environment(\.kasoAccent) var accent

Color.kaso.brand  // automatically uses the user's chosen accent
```

## 10. General Rules

| Rule | Example |
|---------|-------|
| Token > raw value | `Spacing.md` not `16` |
| Semantic > literal color | `Color.kaso.danger` not `.red` |
| Numeric font for amounts | `.font(.kaso.numericLarge)` |
| Existing component > custom build | `KasoButton` not custom `Button` |
| Modifier helper when possible | `.kasoCard()` not a stack of modifiers |

## 11. When Extension Is Needed

If a token/component is missing, do not temporarily hardcode it. Process:

1. Propose adding it to `KasoDesignSystem`
2. Update Figma source of truth
3. Generate token JSON → Swift
4. Create a separate PR for the design system
5. Only then use it in the feature
