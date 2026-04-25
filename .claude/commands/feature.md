---
description: Scaffold một TCA Feature module mới dưới Packages/Features/
argument-hint: <FeatureName>
---

Tạo module TCA feature mới với tên **$1**.

## Bước thực hiện

1. Tạo thư mục `Packages/Features/$1Feature/` với layout:
   ```
   $1Feature/
   ├── Package.swift
   ├── Sources/
   │   └── $1Feature/
   │       ├── $1Feature.swift          (Reducer)
   │       ├── $1View.swift             (SwiftUI View)
   │       └── $1Preview.swift          (#Preview cho dev)
   └── Tests/
       └── $1FeatureTests/
           ├── $1FeatureTests.swift     (Reducer test với TestStore)
           └── $1ViewSnapshotTests.swift
   ```

2. **Package.swift** phải:
   - `swift-tools-version: 6.0`
   - Dependency `swift-composable-architecture` từ workspace
   - Dependency `KasoDesignSystem`, `KasoFoundation` từ workspace
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
   - Body trống ban đầu, dùng token từ `KasoDesignSystem`
   - Có `.task { await store.send(.task).finish() }`

5. **Test** (`$1FeatureTests.swift`):
   - Dùng `@Test` (Swift Testing) + `TestStore`
   - Ít nhất 1 test cho `.task`

6. Chạy `tuist generate` (hoặc `swift package generate-xcodeproj`) sau khi xong.
7. Báo user: package đã sẵn sàng, gợi ý import vào `App` target.

## Kiểm tra trước khi báo done

- File compile clean (`swift build --package-path Packages/Features/$1Feature`)
- Tên không trùng với feature đã có (search `Packages/Features/`)
- Đã thêm vào CLAUDE.md feature list nếu cần

## Cấm

- Không tạo `ViewModel` — phải dùng Reducer
- Không tạo file rỗng "TODO sau" — implement skeleton hoàn chỉnh
- Không hardcode color/font — dùng `KasoDesignSystem` token
