---
description: Scaffold a new TCA Feature module under Packages/Features/
---

You are tasked with creating a new TCA feature module. The feature name comes from the first user-provided argument (placeholder: `$FEATURE_NAME`).

## Requirements

Create this structure under `Packages/Features/${FEATURE_NAME}Feature/`:

```
${FEATURE_NAME}Feature/
├── Package.swift
├── Sources/
│   └── ${FEATURE_NAME}Feature/
│       ├── ${FEATURE_NAME}Feature.swift   (Reducer)
│       ├── ${FEATURE_NAME}View.swift      (SwiftUI View)
│       └── ${FEATURE_NAME}Preview.swift   (#Preview for development)
└── Tests/
    └── ${FEATURE_NAME}FeatureTests/
        ├── ${FEATURE_NAME}FeatureTests.swift
        └── ${FEATURE_NAME}ViewSnapshotTests.swift
```

## Specifications

### `Package.swift`
- `swift-tools-version: 6.0`
- Dependency: `swift-composable-architecture`, `KasoDesignSystem`, `KasoFoundation`
- Test target dependency: `swift-snapshot-testing`

### Reducer
```swift
import ComposableArchitecture
import Foundation

@Reducer
public struct ${FEATURE_NAME}Feature: Sendable {
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

### View
- `@Bindable var store: StoreOf<${FEATURE_NAME}Feature>`
- Body skeleton uses `KasoDesignSystem` tokens
- `.task { await store.send(.task).finish() }`

### Test (Swift Testing)
```swift
import ComposableArchitecture
import Testing
@testable import ${FEATURE_NAME}Feature

@MainActor
@Suite("${FEATURE_NAME}Feature")
struct ${FEATURE_NAME}FeatureTests {
    @Test("initial task")
    func task() async {
        let store = TestStore(initialState: ${FEATURE_NAME}Feature.State()) {
            ${FEATURE_NAME}Feature()
        }
        await store.send(.task)
    }
}
```

## Steps

1. Verify the name does not duplicate an existing feature (`ls Packages/Features/`)
2. Create directories + files from the template
3. Build verify: `swift build --package-path Packages/Features/${FEATURE_NAME}Feature`
4. Tell the user the package is ready and suggest importing it into the `App` target

## Forbidden

- Do not create `class ViewModel: ObservableObject`
- Do not create empty "TODO later" files — implement a complete skeleton
- Do not hardcode colors/fonts — use `KasoDesignSystem` tokens
- Do not skip test files

## Output

After finishing, print:
- Paths of created files
- Build command for user verification
- Import snippet for the App target
