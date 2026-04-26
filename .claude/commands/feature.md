---
description: Scaffold a new TCA Feature module under Packages/Features/
argument-hint: <FeatureName>
---

Create a new TCA feature module named **$1**.

## Steps

1. Create the `Packages/Features/$1Feature/` directory with this layout:
   ```
   $1Feature/
   ├── Package.swift
   ├── Sources/
   │   └── $1Feature/
│       ├── $1Feature.swift          (Reducer)
│       ├── $1View.swift             (SwiftUI View)
│       └── $1Preview.swift          (#Preview for development)
   └── Tests/
       └── $1FeatureTests/
           ├── $1FeatureTests.swift     (Reducer test with TestStore)
           └── $1ViewSnapshotTests.swift
   ```

2. **Package.swift** must:
   - `swift-tools-version: 6.0`
   - Dependency `swift-composable-architecture` from the workspace
   - Dependency `KasoDesignSystem`, `KasoFoundation` from the workspace
   - Test target dependency `swift-snapshot-testing`

3. **Reducer** (`$1Feature.swift`):
   ```swift
   import ComposableArchitecture
   import Foundation

   @Reducer
   public struct $1Feature: Sendable {
       @ObservableState
       public struct State: Equatable {
           public init() {}
       }

       public enum Action {
           case task
       }

       public init() {}

       public var body: some Reducer<State, Action> {
           Reduce { state, action in
               switch action {
               case .task:
                   return .none
               }
           }
       }
   }
   ```

4. **View** (`$1View.swift`):
   - `@Bindable var store: StoreOf<$1Feature>`
   - Empty initial body, using tokens from `KasoDesignSystem`
   - Includes `.task { await store.send(.task).finish() }`

5. **Test** (`$1FeatureTests.swift`):
   - Use `@Test` (Swift Testing) + `TestStore`
   - At least 1 test for `.task`

6. Run `tuist generate` (or `swift package generate-xcodeproj`) after finishing.
7. Tell the user the package is ready and suggest importing it into the `App` target.

## Checks Before Reporting Done

- File compile clean (`swift build --package-path Packages/Features/$1Feature`)
- Name does not duplicate an existing feature (search `Packages/Features/`)
- Added to the CLAUDE.md feature list if needed

## Forbidden

- Do not create a `ViewModel` — must use a Reducer
- Do not create empty "TODO later" files — implement a complete skeleton
- Do not hardcode colors/fonts — use `KasoDesignSystem` tokens
