---
description: Scaffold TCA Feature module mới dưới Packages/Features/
---

Bạn được giao tạo TCA feature module mới. Tên feature lấy từ argument đầu tiên user truyền (placeholder: `$FEATURE_NAME`).

## Yêu cầu

Tạo cấu trúc dưới `Packages/Features/${FEATURE_NAME}Feature/`:

```
${FEATURE_NAME}Feature/
├── Package.swift
├── Sources/
│   └── ${FEATURE_NAME}Feature/
│       ├── ${FEATURE_NAME}Feature.swift   (Reducer)
│       ├── ${FEATURE_NAME}View.swift      (SwiftUI View)
│       └── ${FEATURE_NAME}Preview.swift   (#Preview cho dev)
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
- Body skeleton dùng token `KasoDesignSystem`
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

## Bước thực hiện

1. Verify tên không trùng feature đã có (`ls Packages/Features/`)
2. Tạo thư mục + files theo template
3. Build verify: `swift build --package-path Packages/Features/${FEATURE_NAME}Feature`
4. Báo user: package sẵn sàng, gợi ý import vào `App` target

## Cấm

- KHÔNG tạo `class ViewModel: ObservableObject`
- KHÔNG tạo file rỗng "TODO sau" — implement skeleton hoàn chỉnh
- KHÔNG hardcode color/font — dùng `KasoDesignSystem` token
- KHÔNG bỏ qua test file

## Output

Sau khi xong, in:
- Path các file đã tạo
- Lệnh build để user verify
- Snippet import vào App target
