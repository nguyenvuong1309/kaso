---
description: Run tests (unit + snapshot). Optionally filter scope.
---

Run tests for Kaso. Argument:
- none → all tests via SPM
- feature/package name → test that package only
- `snapshot` → snapshot tests
- `failed` → re-run previous failed tests

## Commands

```bash
# All tests (fast)
swift test --parallel

# Specific package
swift test --package-path Packages/Features/${1}Feature --parallel

# Via Xcode (simulator needed for UI tests)
xcodebuild test \
  -scheme Kaso \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -derivedDataPath .build/DerivedData \
  -parallel-testing-enabled YES \
  -resultBundlePath .build/TestResults.xcresult \
  | xcbeautify --renderer terminal
```

## Report

| Metric | Value |
|--------|-------|
| Pass | X |
| Fail | X |
| Skip | X |
| Time | Xs |
| Coverage | X% |

If failing: list `FILE:LINE — test name — reason` + suggested fix.
If coverage drops below threshold (Domain 90%, Features 80%): warn.
If snapshots fail: ask the user about record mode (do not auto re-record).

## After Passing

Suggest next: `/kaso-lint`, `/kaso-audit`, or commit.
If a Swift file was modified without new tests: warn.
