# Kaso — Claude Code Instructions

> Project **Kaso** — an enterprise-grade personal finance iOS app built with SwiftUI + Metal.
> Read carefully before proposing changes or writing code.

## Guiding Documents (Read First)

- **`plan.md`** — all approved features, priorities, and the 6-phase roadmap
- **`tech-stack.md`** — tech stack, architecture, and module structure
- Do not propose features or technologies that conflict with these 2 documents without asking the user first

## Technical Philosophy (Non-Negotiable)

1. **Apple-native first** — do not add a third-party dependency when Apple provides an equivalent solution
2. **Swift 6 strict concurrency** — do not use `@unchecked Sendable`; do not suppress warnings with pragmas
3. **SwiftUI-only** — use UIKit only when SwiftUI truly has no solution. Comment why.
4. **TCA for every feature** — no MVVM, no vanilla `@StateObject`. Reducers are pure; Views contain no logic.
5. **Tests before code** — every reducer must have tests. Domain layer coverage must be ≥90%.
6. **Metal is the moat** — do not hesitate to write shaders for effects. This is Kaso's differentiator.
7. **Privacy by default** — do not log PII. Financial data must be encrypted at rest.

## Code Conventions

### Naming

- **Type**: `UpperCamelCase`. TCA reducers use the `Feature` suffix (for example: `TransactionFeature`)
- **Property/function**: `lowerCamelCase`
- **File**: match the main type name (`TransactionFeature.swift` contains `struct TransactionFeature`)
- **Test file**: `Tests` suffix (`TransactionFeatureTests.swift`)
- **Snapshot file**: `Snapshots` suffix
- **Metal shader**: snake_case file `.metal` + UpperCamelCase function name
- **Vietnamese**: comments may be Vietnamese, but **identifiers must always be English**

### File organization

```swift
// 1. Imports — Apple frameworks first, then third-party, internal last
import Foundation
import SwiftUI
import ComposableArchitecture
import KasoDesignSystem

// 2. Type declaration
@Reducer
struct TransactionFeature {
    // 3. State (nested types first)
    @ObservableState
    struct State { /* ... */ }

    // 4. Action
    enum Action { /* ... */ }

    // 5. Dependencies
    @Dependency(\.transactionRepository) var repository

    // 6. Body
    var body: some Reducer<State, Action> { /* ... */ }
}
```

### Strictly Forbidden

- `force unwrap` (`!`) — except `@IBOutlet` (which Kaso does not use)
- `try!` — replace with `try?` or handle the error
- `Any` / `AnyObject` — type-safe always
- `print()` — use `Logger` from `KasoLogging`
- `DispatchQueue.main.async` — use `await MainActor.run` or `@MainActor`
- `ObservableObject` — use the `@Observable` macro
- `Combine` for new logic — use `AsyncStream`. Use Combine only when an Apple API requires it.
- Mutable singleton state — use `@Dependency` injection

### Recommended

- Default to `let` instead of `var`
- Default to `private`, widening access only when needed
- Use `some View` / `some Reducer` instead of type erasure
- Use `if let x` shorthand (Swift 5.7+) instead of `if let x = x`
- Use trailing closures for the final closure
- Use `guard` for early returns

## Module Structure

Every new feature must live in its own **Swift Package** under `Packages/Features/`. See section 19 of `tech-stack.md`.

**Dependency rules** (must not be violated):

- `App` → `Features` → `Domain` → `Data` → `Core`
- `Features` may depend on `DesignSystem`
- `Domain` **must not** depend on `Features` or `Data`
- Each `Feature` package must build and `#Preview` independently

## Standard Workflow for Each Task

1. **Understand the request** — read `plan.md` to find the corresponding feature when relevant
2. **Plan** — propose the approach to the user if the task takes >30 minutes
3. **Test first** — write failing tests for reducer/domain logic
4. **Implement** — follow the conventions above
5. **Snapshot test** — write snapshots for every new view
6. **Lint & format** — run `swiftlint` + `swiftformat` (automated through hooks)
7. **Clean build** — `tuist build` with no warnings
8. **Preview** — check light + dark + large Dynamic Type

## SwiftUI patterns

### Correct

```swift
struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>

    var body: some View {
        List {
            ForEach(store.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
        .task { await store.send(.task).finish() }
    }
}
```

### Incorrect — Will Be Rejected

```swift
// ObservableObject + @StateObject
class ViewModel: ObservableObject { /* ... */ }

// Logic in view body
struct BadView: View {
    var body: some View {
        let total = transactions.reduce(0) { $0 + $1.amount }
        Text("\(total)")
    }
}

// DispatchQueue
DispatchQueue.main.async { self.update() }
```

## Metal patterns

- Place `.metal` files under `Sources/.../Shaders/`
- Every shader must have a DocC comment describing input/output
- Prefer SwiftUI integration through `.colorEffect`, `.distortionEffect`, `.layerEffect` before reaching for `MTKView`
- Use `MTKView` only for complex state (60K+ data points, particle systems)
- Test shaders with snapshots — render into `CGImage` and compare

## Design System

Do not hardcode colors, fonts, spacing, or radius. Use tokens from `KasoDesignSystem`:

| Correct | Incorrect |
|------|-----|
| `Color.kaso.surfacePrimary` | `Color(hex: "#1A1A1A")` |
| `Font.kaso.titleLarge` | `.font(.system(size: 28, weight: .bold))` |
| `Spacing.md` (= 16pt) | `.padding(16)` |

New components must include `#Preview` for light + dark + Dynamic Type XL.

## Testing

- **Unit test**: Swift Testing (`@Test`) for new code, XCTest for legacy
- **Reducer test**: TCA `TestStore` — assert every state change
- **Snapshot test**: Pointfree SnapshotTesting for every view component
- **UI test**: Maestro flows for critical paths (onboarding, log expense, paywall)

```swift
import Testing
@testable import TransactionDomain

@Test("calculates monthly total correctly")
func monthlyTotal() async {
    let transactions: [Transaction] = [/* ... */]
    let total = transactions.monthlyTotal(for: Date())
    #expect(total == 1_500_000)
}
```

## Localization

- App defaults to Vietnamese and supports English
- Use **String Catalog** (`.xcstrings`) — do not use old `.strings` files
- Format money with `Decimal.formatted(.currency(code: "VND"))`
- Format dates with `Date.formatted(.dateTime.locale(.current))`
- Do not hardcode "VND" or the Vietnamese dong symbol in UI strings

## Git workflow

- Branch: `feat/`, `fix/`, `refactor/`, `chore/` + kebab-case
- Commit: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`)
- Do not commit unless the user approves
- Do not `git push` unless the user confirms
- Do not use `--no-verify` to skip hooks unless the user requests it

## When Errors Occur

1. **Read the error message carefully** — Swift compiler errors are very detailed
2. **Do not suppress warnings** — fix the root cause
3. **Do not add `@MainActor` blindly** — understand why concurrency is complaining
4. **Clean build** — do not tolerate warnings in CI

---

*Update these conventions as the codebase matures. Do not keep old rules merely because of history.*
