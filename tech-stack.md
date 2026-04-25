# Kaso — Tech Stack Enterprise

> Stack công nghệ cho app **Kaso** — quản lý tài chính cá nhân iOS. Định hướng **enterprise-grade** với trọng tâm **SwiftUI + Metal**, ưu tiên giao diện cao cấp, animation 120fps mượt mà và trải nghiệm người dùng vượt trội.

---

## Mục lục

1. [Triết lý kỹ thuật](#1-triết-lý-kỹ-thuật)
2. [Nền tảng cốt lõi](#2-nền-tảng-cốt-lõi)
3. [Kiến trúc ứng dụng](#3-kiến-trúc-ứng-dụng)
4. [UI Layer — SwiftUI](#4-ui-layer--swiftui)
5. [Rendering Layer — Metal](#5-rendering-layer--metal)
6. [Design System](#6-design-system)
7. [Animation & Motion](#7-animation--motion)
8. [State Management](#8-state-management)
9. [Data & Persistence](#9-data--persistence)
10. [Networking & Backend](#10-networking--backend)
11. [AI / ML](#11-ai--ml)
12. [Bảo mật & Quyền riêng tư](#12-bảo-mật--quyền-riêng-tư)
13. [Tích hợp hệ sinh thái Apple](#13-tích-hợp-hệ-sinh-thái-apple)
14. [Monetization](#14-monetization)
15. [Analytics & Observability](#15-analytics--observability)
16. [Testing](#16-testing)
17. [DevOps & CI/CD](#17-devops--cicd)
18. [Tooling & Developer Experience](#18-tooling--developer-experience)
19. [Cấu trúc module đề xuất](#19-cấu-trúc-module-đề-xuất)
20. [Lộ trình áp dụng](#20-lộ-trình-áp-dụng)

---

## 1. Triết lý kỹ thuật

| Nguyên tắc | Mô tả |
|---|---|
| **Apple-native first** | Ưu tiên framework chính chủ Apple để được hỗ trợ lâu dài, tận dụng tối đa hardware (Neural Engine, Metal GPU, ProMotion 120Hz) |
| **Performance-obsessed** | Mọi animation phải đạt 120fps trên iPhone 15 Pro trở lên, 60fps trên thiết bị cũ. Cold start dưới 800ms |
| **Modular monolith** | Codebase chia thành Swift Packages độc lập theo domain — dễ test, dễ scale team, build incremental nhanh |
| **Type-safe everywhere** | Tận dụng Swift 6 strict concurrency, tránh hoàn toàn `Any`, force-unwrap. Compile-time safety > runtime check |
| **Privacy by default** | Dữ liệu tài chính phải mã hoá at-rest và in-transit. Mặc định không gửi telemetry chứa PII |
| **Offline-first** | App phải dùng được 100% offline. Sync chỉ là tính năng cộng thêm, không phải dependency |

---

## 2. Nền tảng cốt lõi

### 2.1 Ngôn ngữ & SDK

| Công nghệ | Phiên bản | Lý do chọn |
|---|---|---|
| **Swift** | 6.0+ | Strict concurrency, typed throws, ownership model — bắt buộc cho enterprise |
| **Xcode** | 16+ | Hỗ trợ Swift 6, Predictive Code Completion, mới nhất cho iOS 18 |
| **iOS Deployment Target** | 17.0+ | Bao phủ ~92% thiết bị active, đồng thời có `@Observable` macro, SwiftData, Swift Charts 2 |
| **Multi-platform** | iOS, iPadOS, macOS (Catalyst hoặc native), watchOS, visionOS | Tận dụng SwiftUI multi-platform để mở rộng |

### 2.2 Build System

| Công cụ | Vai trò |
|---|---|
| **Swift Package Manager (SPM)** | Quản lý dependency và modular hoá — không dùng CocoaPods/Carthage |
| **Tuist** | Generate `.xcodeproj` từ Swift code — tránh merge conflict, đảm bảo project structure consistent giữa team |
| **Mise / asdf** | Quản lý phiên bản tools (Xcode-select, Swift, Ruby cho Fastlane) |

---

## 3. Kiến trúc ứng dụng

### 3.1 Pattern chính: **TCA (The Composable Architecture)**

Lý do chọn TCA (by Pointfree.co) thay vì MVVM:

- **Unidirectional data flow** — debug dễ hơn, không có race condition
- **Reducer thuần tuý** — test 100% logic không cần UI
- **Dependency injection built-in** — swap fake/mock cho test/preview
- **Composable** — feature scope rõ ràng, không leak state
- **Industry-validated** — đã dùng ở Robinhood, Telnyx, nhiều fintech lớn

```swift
@Reducer
struct TransactionFeature {
    @ObservableState
    struct State { /* ... */ }
    enum Action { /* ... */ }
    var body: some Reducer<State, Action> { /* ... */ }
}
```

### 3.2 Architectural layers

```
┌──────────────────────────────────────────────┐
│  App Layer (Composition Root, Routing)       │
├──────────────────────────────────────────────┤
│  Feature Modules (TCA Reducers + Views)      │
├──────────────────────────────────────────────┤
│  Domain Layer (Pure Swift, business logic)   │
├──────────────────────────────────────────────┤
│  Data Layer (Repositories, Persistence, API) │
├──────────────────────────────────────────────┤
│  Core Layer (Foundation, Logging, Crypto)    │
└──────────────────────────────────────────────┘
```

### 3.3 Navigation

- **NavigationStack** + **TCA `@Presents`** cho deep-linking type-safe
- **TCACoordinator** pattern cho flow phức tạp (onboarding, paywall)
- Universal Links + Deep Links qua `@Environment(\.openURL)`

---

## 4. UI Layer — SwiftUI

### 4.1 Framework chính

| Framework | Sử dụng |
|---|---|
| **SwiftUI** | Toàn bộ UI — không UIKit trừ trường hợp bất khả kháng |
| **UIKit (interop)** | Camera (`UIImagePickerController`), một vài API chưa có SwiftUI bridge |
| **Observation** | `@Observable` macro thay cho `ObservableObject` (iOS 17+) |
| **SwiftUI Introspect** | Tinh chỉnh sâu các view khi SwiftUI API chưa expose |

### 4.2 Component & Layout

- **`Grid`, `LazyVGrid`** — layout linh hoạt cho dashboard
- **`ViewThatFits`** — adaptive layout cho mọi kích thước
- **`AnyLayout`** — chuyển đổi layout động (Stack ↔ Grid theo orientation)
- **`ContainerRelativeShape`** — design responsive cho widget
- **`Custom Layout Protocol`** — viết layout riêng (radial menu, masonry grid)

### 4.3 Charts

| Lựa chọn | Khi dùng |
|---|---|
| **Swift Charts (Apple)** | 80% biểu đồ chuẩn — bar, line, pie, area |
| **Custom Metal-rendered charts** | Biểu đồ 60K+ data points (lịch sử giao dịch dài hạn), candlestick chart cho đầu tư |
| **DGCharts (fork Charts)** | Khi cần feature mà Swift Charts chưa có |

---

## 5. Rendering Layer — Metal

> Metal là **vũ khí cạnh tranh** của Kaso — dùng để render những hiệu ứng và biểu đồ mà các app fintech khác không thể làm.

### 5.1 Use cases cụ thể

| Tính năng | Lý do dùng Metal |
|---|---|
| **What-if simulator** | Slider real-time điều chỉnh số liệu, animation số nhảy mượt 120fps trên hàng triệu data point |
| **Spending heatmap** | Render heatmap địa lý overlay trên MapKit, phải mượt khi pan/zoom |
| **Spending DNA infographic** | Particle system, fluid simulation, generative art cho year-in-review |
| **Wrapped cards** | Shader-based gradient mesh, noise, displacement effects |
| **Liquid balance indicator** | Metaball/SDF rendering cho thanh số dư dạng chất lỏng |
| **Confetti & celebration** | Particle system khi đạt mục tiêu, lên level |
| **Custom blur & glassmorphism** | Variable blur (giống Dynamic Island), không thể làm bằng `Material` |

### 5.2 Tech stack Metal

| Công nghệ | Mục đích |
|---|---|
| **Metal 3** | Core API — shader, compute, render pipeline |
| **MetalKit** | `MTKView` integration, texture loading |
| **Metal Performance Shaders (MPS)** | Image processing accelerated |
| **MetalFX** | Upscaling cho hiệu ứng phức tạp |
| **Core Animation Metal Layer** | Bridge giữa Metal và Core Animation |
| **MSL (Metal Shading Language)** | Viết vertex/fragment/compute shaders |

### 5.3 SwiftUI ↔ Metal bridge

```swift
struct MetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView { /* ... */ }
}

// Hoặc dùng `Canvas` + `GraphicsContext.drawLayer` (iOS 17+)
// để có hiệu ứng đơn giản mà không cần MTKView
```

| Lựa chọn | Khi dùng |
|---|---|
| **`Canvas` + Metal shader** | Hiệu ứng đơn giản, integrate với SwiftUI (iOS 17+) |
| **`MTKView` qua `UIViewRepresentable`** | Render chuyên sâu, full control |
| **`.colorEffect`, `.distortionEffect`, `.layerEffect`** | Apply MSL shader trực tiếp lên view (iOS 17+) — **dùng nhiều nhất** |
| **`SceneKit` + Metal** | 3D objects (nếu cần) |

### 5.4 Thư viện hỗ trợ

- **MetalPetal** — image processing pipeline declarative
- **GPUImage3** — filter và effect chain
- **SwiftUIShaders** — wrapper SwiftUI thuận tiện cho shader

---

## 6. Design System

### 6.1 Design tokens

Quản lý qua **Swift Package** riêng `KasoDesignSystem`:

```
KasoDesignSystem/
├── Sources/
│   ├── Tokens/
│   │   ├── Colors.swift       (semantic colors)
│   │   ├── Typography.swift   (Dynamic Type scale)
│   │   ├── Spacing.swift      (4-pt grid)
│   │   ├── Radius.swift
│   │   ├── Shadow.swift
│   │   └── Motion.swift       (spring presets)
│   ├── Components/
│   │   ├── KasoButton.swift
│   │   ├── KasoCard.swift
│   │   ├── KasoTextField.swift
│   │   └── KasoChart.swift
│   └── Modifiers/
```

### 6.2 Pipeline thiết kế

| Công cụ | Vai trò |
|---|---|
| **Figma** | Design tool chính |
| **Tokens Studio for Figma** | Đồng bộ design token Figma ↔ JSON |
| **Style Dictionary** | Generate Swift code từ JSON tokens |
| **SF Symbols 6** | Iconography — variable icons, symbol effects |
| **Custom font** | SF Pro Rounded (mặc định) + 1 display font (Inter / Geist) |
| **SwiftUI Previews + PreviewSnapshot** | Visual regression testing |

### 6.3 Theming

- **Color assets catalog** với Light/Dark/High-contrast variants
- **`@Environment(\.colorScheme)`** + custom `KasoTheme` environment
- Hỗ trợ **accent color tuỳ chỉnh** (user chọn từ palette)
- **App Icon variants** — alternate icons via `setAlternateIconName`

### 6.4 Accessibility (bắt buộc enterprise)

- **Dynamic Type** — toàn bộ text scale theo system
- **VoiceOver labels** đầy đủ cho mọi component
- **Reduce Motion** — fallback animation khi user bật
- **High Contrast** color variants
- **Voice Control** + **Switch Control** support
- **Audio descriptions** cho video onboarding

---

## 7. Animation & Motion

### 7.1 SwiftUI native

| API | Use case |
|---|---|
| **`.animation(.spring)`** | Default cho mọi state change |
| **`PhaseAnimator`** | Multi-step animation (iOS 17+) |
| **`KeyframeAnimator`** | Choreographed animation (iOS 17+) |
| **`.transition(.symbolEffect)`** | SF Symbol animations |
| **`MatchedGeometryEffect`** | Hero transitions giữa view |
| **`.containerRelativeFrame`** | Responsive animation |

### 7.2 Thư viện bổ sung

| Library | Mục đích |
|---|---|
| **Pow (by Movin)** | Premium SwiftUI transition pack — anvil, pop, glare, particle |
| **Lottie** | Animation từ After Effects (cho onboarding, empty state) |
| **Rive** | Animation tương tác (state machine) — tốt hơn Lottie cho UI animation |
| **SwiftUIX** | Component và modifier mở rộng |

### 7.3 Quy tắc motion

- **Duration**: 200–400ms cho micro-interaction, 500–800ms cho transition lớn
- **Easing**: `.spring(response: 0.4, dampingFraction: 0.8)` mặc định
- **Haptic feedback**: dùng `SensoryFeedback` (iOS 17+) — đồng bộ animation với haptic
- **120Hz ProMotion**: viết animation với `CADisplayLink` chạy 120Hz cho rendering Metal

---

## 8. State Management

### 8.1 Trong feature (TCA)

```swift
@Reducer struct Feature { /* state, action, reducer */ }
@Observable @MainActor class Store<F: Reducer> { /* ... */ }
```

### 8.2 Cross-feature

- **Shared state** qua TCA `@Shared` macro (iOS 17+, từ TCA 1.10+)
- **Environment values** cho theme, locale, feature flag
- **`AppStorage` + `SceneStorage`** cho user preference đơn giản

### 8.3 Concurrency

- **Swift Concurrency** (async/await, actors) — bắt buộc Swift 6 strict mode
- **`@MainActor` isolation** rõ ràng cho UI
- **`AsyncStream`** thay cho Combine ở chỗ có thể
- **`TaskGroup`** cho parallel work
- **Combine** chỉ dùng khi tương tác với Apple API (CloudKit, etc.)

---

## 9. Data & Persistence

### 9.1 Local storage

| Công nghệ | Vai trò |
|---|---|
| **SwiftData** | Primary database — model giao dịch, ngân sách, mục tiêu |
| **GRDB.swift** | Khi cần query SQL phức tạp (báo cáo, aggregation lớn) — fallback từ SwiftData |
| **FileManager + JSON** | Cache nhẹ, draft transaction |
| **Keychain Services** | Token, biometric secret, encryption key |
| **UserDefaults / AppStorage** | Setting đơn giản, non-sensitive |

### 9.2 Sync

| Công nghệ | Vai trò |
|---|---|
| **CloudKit** | Sync iCloud — primary, miễn phí, end-to-end encrypted |
| **CKSyncEngine** | API mới (iOS 17+) — quản lý sync state đơn giản hơn |
| **CRDT (Y.swift hoặc tự viết)** | Conflict resolution cho family account multi-device |

### 9.3 Encryption at-rest

- **CryptoKit** — AES-GCM 256 cho dữ liệu nhạy cảm
- **Secure Enclave** — protect symmetric key bằng biometric
- **Data Protection Class** — Complete File Protection cho database file

---

## 10. Networking & Backend

### 10.1 Client

| Lựa chọn | Khi dùng |
|---|---|
| **URLSession + async/await** | Default — đủ cho 90% case |
| **Alamofire** | Multipart upload, retry policy phức tạp |
| **OpenAPI Generator (Apple)** | Generate type-safe client từ OpenAPI spec |

### 10.2 Backend (nếu tự host)

| Công nghệ | Mục đích |
|---|---|
| **Vapor 4** (Swift) | API server cùng ngôn ngữ với app — share model code |
| **PostgreSQL** | Database chính (managed via Supabase / Neon / RDS) |
| **Redis** | Cache, rate limiting, queue |
| **TimescaleDB** | Time-series analytics cho benchmark ẩn danh |

### 10.3 BaaS (alternative — khuyến nghị giai đoạn MVP)

| Lựa chọn | Lý do |
|---|---|
| **Supabase** | Postgres + Auth + Storage + Edge Functions, có Swift SDK chính thức |
| **Firebase** | Auth + Firestore + Cloud Functions — nhưng vendor lock-in cao |
| **CloudKit (server-side)** | Cho gia đình muốn full Apple ecosystem |

### 10.4 Authentication

- **Sign in with Apple** (bắt buộc theo App Store guideline khi có third-party auth)
- **Passkey** — passwordless qua iCloud Keychain
- **Email magic link** (qua Resend / Postmark) cho web sign-in

---

## 11. AI / ML

### 11.1 On-device

| Framework | Vai trò |
|---|---|
| **Vision** | OCR hoá đơn — `VNRecognizeTextRequest` (Vietnamese hỗ trợ tốt từ iOS 17) |
| **VisionKit** | `DataScannerViewController` — scan text/barcode real-time |
| **Core ML** | Phân loại danh mục giao dịch, anomaly detection |
| **Create ML** | Train classifier từ data Việt Nam (tên cửa hàng → danh mục) |
| **Natural Language** | Tokenize, sentiment analysis cho note giao dịch |
| **Speech** | Voice input — "Ăn sáng 40 nghìn" |
| **Foundation Models** (iOS 18.1+) | Apple Intelligence on-device LLM cho chatbot |

### 11.2 Cloud AI

| API | Vai trò |
|---|---|
| **Claude API (Anthropic)** | Chatbot tài chính cá nhân, viết "Future self letter" — chọn vì context window lớn và an toàn cho finance |
| **OpenAI / GPT** | Backup option |
| **Apple PCC** (Private Cloud Compute) | Cho task quá lớn cho on-device — privacy preserved |

### 11.3 Pipeline

- **On-device first** — chỉ gửi cloud khi không thể xử lý local
- **Differential privacy** cho aggregate analytics
- **PII redaction** trước khi gửi prompt lên cloud

---

## 12. Bảo mật & Quyền riêng tư

### 12.1 Authentication & Authorization

| Tech | Use case |
|---|---|
| **LocalAuthentication** | Face ID / Touch ID / Optic ID gating app launch |
| **App Attest** | Verify app integrity trước khi gọi sensitive API |
| **DeviceCheck** | Anti-fraud, device fingerprinting privacy-friendly |

### 12.2 Network security

- **App Transport Security (ATS)** strict mode
- **Certificate pinning** qua **TrustKit**
- **TLS 1.3** mandatory
- **Public Key Pinning** với rotation strategy

### 12.3 Code security

- **Jailbreak detection** — `IOSSecuritySuite`
- **Anti-debugging** trong production build
- **Symbol stripping** + **bitcode** disabled (tránh leak)
- **Obfuscation** cho string nhạy cảm — **SwiftShield**

### 12.4 Compliance

- **GDPR** — data export, right to delete, consent
- **App Privacy Manifest** (`PrivacyInfo.xcprivacy`) — bắt buộc từ 2024
- **Required Reason API** declaration
- **Tracking transparency** — App Tracking Transparency framework

---

## 13. Tích hợp hệ sinh thái Apple

| Framework | Tính năng |
|---|---|
| **WidgetKit** | Widget Home Screen + Lock Screen + StandBy |
| **ActivityKit** | Live Activity + Dynamic Island cho daily spending |
| **App Intents** | Siri Shortcuts, Spotlight integration, Apple Intelligence actions |
| **AppShortcuts** | "Hey Siri, log expense 40k coffee" |
| **WatchKit / SwiftUI watchOS** | Companion app Apple Watch |
| **PassKit** | Apple Pay tracking, Apple Wallet pass cho subscription receipt |
| **MapKit** | Spending map, heatmap |
| **PencilKit** | Annotate hoá đơn (iPad) |
| **PhotosUI** | `PhotosPicker` chọn ảnh hoá đơn |
| **MessageUI** | Share Wrapped via iMessage |
| **StoreKit 2** | In-app purchase, subscription |
| **BackgroundTasks** | Sync, OCR background, anomaly detection nightly |
| **PushKit + UNUserNotificationCenter** | Notification rich, action |

---

## 14. Monetization

| Layer | Công cụ |
|---|---|
| **In-App Purchase** | **StoreKit 2** native (async/await API) |
| **Subscription management** | **RevenueCat** — wrapper trên StoreKit 2 + analytics + A/B test paywall + cross-platform |
| **Paywall UI** | **Superwall** hoặc tự build với SwiftUI + Metal effect |
| **Receipt validation** | Server-side qua App Store Server API |
| **Promo / Referral** | RevenueCat Offerings + custom logic |

---

## 15. Analytics & Observability

### 15.1 Product analytics

| Tool | Lý do chọn |
|---|---|
| **TelemetryDeck** | Privacy-first, swift-native, không có PII, đủ cho 80% use case |
| **PostHog** | Self-host được, feature flag + analytics + session replay all-in-one |
| **Mixpanel / Amplitude** | Khi cần funnel analysis sâu (giai đoạn growth) |

### 15.2 Crash & error

| Tool | Mục đích |
|---|---|
| **Sentry** | Crash report + performance monitoring + release tracking |
| **MetricKit** (Apple native) | Battery, hang, scroll performance từ user thật |
| **OSLog + Logger** | Structured logging on-device |

### 15.3 Performance

- **Instruments** (Time Profiler, Allocations, Metal System Trace) — daily check
- **XCTest performance metrics** — assert FPS, launch time trong CI
- **SwiftUI Profiler** — track unnecessary view body re-evaluation

---

## 16. Testing

### 16.1 Test framework

| Framework | Use case |
|---|---|
| **Swift Testing** | Default cho unit test mới (Xcode 16+) — macro-based, parallel |
| **XCTest** | Legacy + UI test |
| **TCA TestStore** | Test reducer 100% deterministic |

### 16.2 Specialized

| Tool | Mục đích |
|---|---|
| **PointFree SnapshotTesting** | Visual regression testing cho mọi screen + dark mode |
| **ViewInspector** | Test SwiftUI view hierarchy |
| **Cuckoo / Mockingbird** | Auto-generate mock |
| **XCUITest + Robot pattern** | E2E test critical flow (onboarding, paywall, log expense) |
| **Maestro** | Cross-platform E2E test, dễ viết hơn XCUITest |

### 16.3 Coverage targets

- Domain layer: **≥ 90%**
- Feature reducers: **≥ 80%**
- Repository / data layer: **≥ 85%**
- UI views: snapshot test cho mọi component

---

## 17. DevOps & CI/CD

### 17.1 CI/CD pipeline

| Tool | Vai trò |
|---|---|
| **GitHub Actions** | Pipeline chính — lint, test, build, snapshot |
| **Xcode Cloud** | Apple-native, integrate TestFlight tốt nhất, free 25h/month |
| **Fastlane** | Tự động hoá release, screenshot, metadata App Store |
| **Bitrise** | Alternative cho team lớn, có macOS dedicated |

### 17.2 Distribution

- **TestFlight** — internal + external beta
- **Firebase App Distribution** — alternative cho ad-hoc build
- **App Store Connect API** — automate metadata, in-app event

### 17.3 Release strategy

- **Semantic versioning** (`MAJOR.MINOR.PATCH`)
- **Phased release** (1% → 10% → 50% → 100% trong 7 ngày) qua App Store
- **Feature flag** cho rollback nhanh không cần update binary
- **Kill switch** cho tính năng critical

---

## 18. Tooling & Developer Experience

### 18.1 Code quality

| Tool | Mục đích |
|---|---|
| **SwiftLint** | Static analysis, style enforce |
| **SwiftFormat** | Auto-format on save |
| **Periphery** | Detect unused code |
| **Sourcery** | Code generation (mock, equatable) |
| **swift-format** (Apple) | Backup formatter |

### 18.2 Pre-commit

- **Lefthook** — fast pre-commit hook manager
- Run lint + format + unit test changed files

### 18.3 Documentation

- **DocC** — generate documentation từ doc comment
- **Mermaid** trong DocC cho architecture diagram
- **Notion** team wiki cho decision log

### 18.4 Feature flags

| Tool | Khi dùng |
|---|---|
| **PostHog Feature Flags** | Đi kèm analytics, miễn phí tier rộng |
| **LaunchDarkly** | Enterprise, advanced targeting |
| **Firebase Remote Config** | Đơn giản, free, đủ cho config A/B test |

---

## 19. Cấu trúc module đề xuất

```
Kaso/
├── App/                              # Composition root
│   └── KasoApp.swift
├── Packages/
│   ├── Core/
│   │   ├── KasoFoundation/           # Extensions, utilities
│   │   ├── KasoCrypto/               # Encryption, keychain
│   │   ├── KasoLogging/              # Structured logger
│   │   └── KasoNetworking/           # HTTP client
│   ├── DesignSystem/
│   │   ├── KasoDesignSystem/         # Tokens, components
│   │   ├── KasoMetalEffects/         # Metal shaders, MTKView
│   │   └── KasoMotion/               # Animation, haptic
│   ├── Domain/
│   │   ├── TransactionDomain/
│   │   ├── BudgetDomain/
│   │   ├── GoalDomain/
│   │   ├── InsightDomain/            # AI insight, anomaly
│   │   └── SubscriptionDomain/       # IAP, RevenueCat
│   ├── Data/
│   │   ├── PersistenceKit/           # SwiftData stack
│   │   ├── SyncKit/                  # CloudKit
│   │   └── APIKit/                   # Backend client
│   ├── Features/
│   │   ├── OnboardingFeature/
│   │   ├── DashboardFeature/
│   │   ├── TransactionFeature/
│   │   ├── BudgetFeature/
│   │   ├── GoalFeature/
│   │   ├── InsightFeature/
│   │   ├── WhatIfFeature/            # Metal-heavy
│   │   ├── WrappedFeature/           # Metal-heavy
│   │   ├── SettingsFeature/
│   │   └── PaywallFeature/
│   └── Integrations/
│       ├── WidgetExtension/
│       ├── WatchApp/
│       ├── LiveActivity/
│       └── AppIntents/
├── Tests/
└── Tuist/
    ├── Project.swift
    └── Config.swift
```

**Nguyên tắc dependency**:
- `App` → `Features` → `Domain` → `Data` → `Core`
- `Features` được phép phụ thuộc `DesignSystem`
- **Cấm**: `Domain` phụ thuộc `Features` hoặc `Data`
- Mỗi `Feature` package có thể build và preview độc lập

---

## 20. Lộ trình áp dụng

### Phase 0 — Setup (tuần 1)
- Khởi tạo monorepo + Tuist + SPM packages
- Setup CI (GitHub Actions): lint + test + build
- Khởi tạo `KasoDesignSystem` với token từ Figma
- Setup TCA + Observation skeleton

### Phase 1 — MVP (tuần 2–5)
- Core feature: nhập tay, budget, dashboard
- SwiftData stack + repository pattern
- Snapshot test cho mọi screen
- Internal TestFlight

### Phase 2 — Metal differentiation (tuần 6–10)
- Custom Metal chart cho dashboard
- Liquid balance indicator
- Confetti & celebration shader
- What-if simulator MVP với Metal

### Phase 3 — Automation (tuần 11–14)
- Vision OCR hoá đơn
- Subscription detection (Core ML model)
- App Intents + Siri Shortcuts
- Widget + Live Activity

### Phase 4 — Sync & Cloud (tuần 15–17)
- CloudKit sync với CKSyncEngine
- iPad + Mac Catalyst
- Apple Watch companion

### Phase 5 — Monetization (tuần 18–20)
- RevenueCat integration
- Paywall với Metal effect
- Subscription analytics

### Phase 6 — Growth (tuần 21+)
- Wrapped feature (Metal generative art)
- Spending DNA infographic
- Apple Watch deep features
- visionOS adaptation

---

## Tóm tắt — Top 10 quyết định kỹ thuật quan trọng nhất

1. **Swift 6 strict concurrency** — không thoả hiệp về type safety
2. **TCA + Observation** — single source of truth, testability cao
3. **SwiftData primary, GRDB fallback** — modern + escape hatch khi cần
4. **Metal cho mọi hiệu ứng wow** — đây là moat của Kaso
5. **CloudKit thay vì backend tự host** — tiết kiệm chi phí, privacy bonus
6. **On-device AI first** — Vision + Core ML + Foundation Models
7. **Tuist + SPM modular** — scale team không pain
8. **RevenueCat cho subscription** — không tự build, tập trung vào product
9. **TelemetryDeck + Sentry** — analytics privacy-first + crash report đầy đủ
10. **Xcode Cloud + Fastlane** — release pipeline tự động hoá hoàn toàn

---

*Tài liệu định hướng kỹ thuật cho dự án **Kaso** — quản lý tài chính cá nhân, iOS-first, enterprise-grade.*
*Cập nhật lần cuối: 2026-04-26.*
